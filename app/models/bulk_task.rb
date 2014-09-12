class BulkTask < ActiveRecord::Base

  validates_presence_of :directory
  validates :status, inclusion: { in: %w(new ingesting errored ingested reviewed), message: "%{value} is not a valid status" }

  delegate :new?, :ingesting?, :errored?, :ingested?, :reviewed?, :to => :status

  has_many :bulk_task_children, :dependent => :destroy

  before_create :generate_children
  after_initialize :update_status

  def self.refresh
    (disk_bulk_folders - relative_db_bulk_folders).each do |dir|
      BulkTask.new(:directory => dir).save
    end
  end

  def self.disk_bulk_folders
    Dir.glob(File.join(APP_CONFIG.batch_dir, '*')).select { |f| File.directory? f }.map{|x| Pathname.new(x).basename.to_s}
  end

  def self.relative_db_bulk_folders
    BulkTask.pluck(:directory).map{|x| Pathname.new(x).basename.to_s}
  end

  def status
    ActiveSupport::StringInquirer.new(attributes['status'])
  end

  def type
    @type ||= :csv unless Dir.glob(File.join(absolute_path, '*.csv')).empty?
    @type ||= :bag
  end

  def absolute_path
    Pathname(directory).absolute? ? directory : File.join(APP_CONFIG.batch_dir, directory)
  end

  def ingest!
    bulk_task_children.each do |child|
      child.queue_ingest! unless child.ingesting?
    end
    self.status = "ingesting"
    save
  end

  def assets
    @assets ||= bulk_task_children.map(&:asset).compact
  end

  def asset_ids
    @asset_ids ||= bulk_task_children.fetch(:ingested_pid)
  end

  private

  def children_statuses
    @children_statuses ||= bulk_task_children.pluck(:status).uniq
  end

  def update_status
    if bulk_task_children.count > 0
      if children_statuses.include?("errored")
        self.status = "errored"
      elsif children_statuses == ["ingested"] && !reviewed?
        self.status = "ingested"
      end
    end
  end

  def generate_children
    send("generate_#{type}_children")
  end

  def generate_bag_children
    Hybag::BulkIngester.new(absolute_path).each do |ingester|
      directory = ingester.bag.bag_dir
      bulk_task_children << BulkTaskChild.new(:target => directory)
    end
  end

end
