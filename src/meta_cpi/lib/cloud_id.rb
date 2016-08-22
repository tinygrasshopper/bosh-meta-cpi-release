require 'timeout'
require 'json'

class CloudIDRepository
  def initialize(filename)
    @filename = filename
  end

  def append(cloud_id)
    safely_mutate_state do |contents|
      contents << cloud_id
      contents
    end
  end

  def find(id, type)
    cloud_id = {}
    safely_mutate_state do |cloud_ids|
      cloud_ids.each do |current|
        cloud_id = current if current["id"] == id and current["type"] == type
      end
      contents
    end
    cloud_id
  end

  private

  #This is totally unsafe
  def safely_mutate_state
    File.open(@filename, File::RDWR|File::CREAT, 0644) do |file|
      Timeout::timeout(1) { file.flock(File::LOCK_EX) }
      content = file.read
      input = if content.empty?
        []
      else
        JSON.parse(content)
      end
      output = yield input
      file.truncate(0)
      file.write(output.to_json)
    end
  end
end

module CloudIDType
  STEMCELL = :stemcell
  INSTANCE = :instance
end
