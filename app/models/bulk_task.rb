class BulkTask < ActiveRecord::Base
  serialize :bulk_errors
  serialize :asset_ids

  validates_presence_of :directory
  validates :status, inclusion: { in: %w(new validating invalid validated processing ingested reviewed deleted failed), message: "%{value} is not a valid status" }

  delegate :new?, :processing?, :validated?, :reviewed?, :validating?, :to => :status

  def self.refresh
    folders = Dir.glob(File.join(APP_CONFIG.batch_dir, '*')).select { |f| File.directory? f }
    (folders - BulkTask.pluck(:directory)).each do |dir|
      dir = Pathname(dir).to_s
      BulkTask.new(:directory => dir).save
    end
    # queue validation on tasks if they are new
    BulkTask.all.each do |task|
      task.queue_validation if task.new? 
    end
  end

  def status
    ActiveSupport::StringInquirer.new(attributes['status'])
  end

  def ingested?
    self.status.ingested? or self.status.reviewed?
  end

  def failed?
    self.status.failed? or self.status.invalid? or self.status.deleted?
  end

  def ingestible?
    (not failed?) and (not ingested?) and (not processing?) and (not validating?)
  end

  def type
    @type ||= :csv unless Dir.glob(File.join(absolute_path, '*.csv')).nil?
    @type ||= :bag
  end

  def absolute_path
    File.join(APP_CONFIG.batch_dir, directory)
  end

  def enqueue
    raise 'Batch job is already in queue.' if processing?
    raise 'Already ingested batch job.' if ingested?
    Resque.enqueue(BulkIngest::Ingest, self.id)
    self.status = 'processing'
    self.save
  end

  def ingest
    raise 'Already ingested batch job.' if ingested?
    begin
      assets = send("ingest_#{type}")
    rescue OregonDigital::CsvBulkIngestible::CsvBatchError => e
      build_errors(e)
      raise e
    end
    self.asset_ids = assets.map { |a| a.pid }
    clear_errors
    self.status = 'ingested'
    self.save
  end

  def delete_assets
    return status if asset_ids.nil?
    self.asset_ids.map { |pid| ActiveFedora::Base.find(:pid => pid).first.delete }
    self.asset_ids = nil
    self.status = 'deleted'
    self.save
  end

  def queue_delete
    self.status = 'processing'
    Resque.enqueue(BulkIngest::Delete, self.id)
    self.save
  end

  def reset!
    delete_assets
    self.status = 'new'
    self.save
  end

  def queue_validation
    return false if type == :bag
    self.status = 'validating'
    Resque.enqueue(BulkIngest::Validation, self.id)
  end

  def validate_metadata
    self.status = send("validate_#{type}")
  end

  def review_assets
    raise 'Batch job has already been review.' if reviewed?
    raise 'Batch job has not yet been processed.' unless ingested?
    raise 'No assets to review.' if asset_ids.nil? or asset_ids.empty?
    asset_ids.each do |asset_id|
      asset = ActiveFedora::Base.find(asset_id).adapt_to_cmodel
      asset.review
    end
    status = 'reviewed'
  end

  def queue_review
    self.status = 'processing'
    Resque.enqueue(BulkIngest::Review, self.id)
    self.save
  end

  private

    def clear_errors
      bulk_errors = nil
    end

    def validate_csv
      return 'validated' if validated?
      begin
        GenericAsset.assets_from_csv(absolute_path)
      rescue OregonDigital::CsvBulkIngestible::CsvBatchError => e
        build_errors(e)
        return 'invalid'
      end
      return 'validated'
    end

    # simply returns new status to indicate that 
    # validation never took place
    # TODO: implement bag validation
    def validate_bag
      'new'
    end
  
    def build_errors(e)
      self.bulk_errors = { 
        :field => e.field_errors,
        :value => e.value_errors,
        :file => e.file_errors
      }
      self.status = 'failed'
    end

    def ingest_csv
      assets = GenericAsset.ingest_from_csv(absolute_path)
    end

    def ingest_bag
      GenericAsset.bulk_ingest_bags(absolute_path)
    end
end
