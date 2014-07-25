class BulkTask < ActiveRecord::Base
  serialize :bulk_errors
  serialize :asset_ids

  validates_presence_of :directory

  after_initialize do
    set_status(:new) if status.nil?
  end

  def self.refresh
    folders = Dir.glob(File.join(APP_CONFIG.batch_dir, '*')).select { |f| File.directory? f }
    folders.each do |dir| 
      dir = Pathname(dir).to_s
      next unless BulkTask.find_by(:directory => dir).nil?
      BulkTask.new(:directory => dir).save
    end
    # queue validation on tasks if they are new
    BulkTask.all.each do |task|
      task.queue_validation if task.new? 
    end
  end

  def status
    self.attributes['status'].nil? ? nil : self.attributes['status'].to_sym
  end

  def absolute_path
    File.join(APP_CONFIG.batch_dir, directory)
  end

  def new?
    self.status.nil? or self.status == :new
  end

  def processing?
    self.status == :processing
  end

  def validating?
    self.status == :validating
  end

  def ingested?
    self.status == :ingested or self.status == :reviewed
  end

  def reviewed?
    self.status == :reviewed
  end

  def failed?
    self.status == :failed or self.status == :invalid or self.status == :deleted 
  end

  def validating?
    self.status == :validating
  end

  def ingestible?
    (not failed?) and (not ingested?) and (not processing?) and (not validating?)
  end

  def type
    return @type if defined?(@type)
    @type = :csv unless Dir.glob(File.join(absolute_path, '*.csv')).nil?
    @type ||= :bag
  end

  def enqueue
    raise 'Batch job is already in queue.' if processing?
    raise 'Already ingested batch job.' if ingested?
    Resque.enqueue(BulkIngest::Ingest, self.id)
    set_status(:processing)
  end

  def ingest
    raise 'Already ingested batch job.' if ingested?
    begin
      if type == :csv
        assets = ingest_csv
      elsif type == :bag
        assets = ingest_bags
      end
    rescue OregonDigital::CsvBulkIngestible::CsvBatchError => e
      build_errors(e)
      raise e
    end
    self.asset_ids = assets.map { |a| a.pid }
    clear_errors
    set_status(:ingested)
  end

  def delete_assets
    return status if asset_ids.nil?
    self.asset_ids.map { |pid| ActiveFedora::Base.find(:pid => pid).first.delete }
    self.asset_ids = nil
    set_status(:deleted)
  end

  def queue_delete
    set_status(:processing)
    Resque.enqueue(BulkIngest::Delete, self.id)
  end

  def reset!
    delete_assets
    set_status :new
  end

  def queue_validation
    return false if type == :bag
    set_status(:validating)
    Resque.enqueue(BulkIngest::Validation, self.id)
  end

  def validate_metadata
    case type
    when :csv
      set_status(validate_csv)
    when :bag
      set_status(validate_bags)
    end
  end

  def review_assets
    raise 'Batch job has already been review.' if status == :reviewed
    raise 'Batch job has not yet been processed.' unless status == :ingested
    raise 'No assets to review.' if asset_ids.nil? or asset_ids.empty?
    asset_ids.each do |asset_id|
      asset = ActiveFedora::Base.find(asset_id).adapt_to_cmodel
      asset.review
    end
    set_status(:reviewed)
  end

  def queue_review
    set_status(:processing)
    Resque.enqueue(BulkIngest::Review, self.id)
  end

  private

    def clear_errors
      bulk_errors = nil
    end

    def validate_csv
      return :validated if status == :validated
      begin
        GenericAsset.assets_from_csv(absolute_path)
      rescue OregonDigital::CsvBulkIngestible::CsvBatchError => e
        build_errors(e)
        return :invalid
      end
      return :validated
    end

    def validate_bags
      :new
    end
  
    def set_status(status)
      statuses = [ :new, 
                   :validating,
                   :invalid,
                   :validated,
                   :processing,
                   :ingested,
                   :reviewed,
                   :deleted,
                   :failed,
                 ]
      raise "Invalid status: #{status}" unless statuses.include? status
      self.status = status
      self.save
    end

    def build_errors(e)
      self.bulk_errors = { 
        :field => e.field_errors,
        :value => e.value_errors,
        :file => e.file_errors
      }
      set_status(:failed)
      self.save
    end

    def ingest_csv
      assets = GenericAsset.ingest_from_csv(absolute_path)
    end

    def ingest_bags
      GenericAsset.bulk_ingest_bags(absolute_path)
    end
end
