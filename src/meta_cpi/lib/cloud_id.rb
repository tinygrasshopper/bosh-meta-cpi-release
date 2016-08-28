require 'timeout'
require 'json'

class CloudIDRepository
  def initialize(datafile, lockfile)
    @datafile = datafile
    @lockfile = lockfile
  end

  def append(cloud_id)
    safely_mutate_state do |contents|
      contents << cloud_id
      contents
    end
  end

  def find(id, type)
    cloud_id = nil
    safely_mutate_state do |cloud_ids|
      cloud_ids.each do |current|
        cloud_id = current if current["id"] == id and current["type"] == type.to_s
      end
      cloud_ids
    end
    cloud_id
  end

  private

  #This is totally unsafe
  def safely_mutate_state
    File.open(@lockfile, File::RDWR|File::CREAT, 0644) do |lock|
      Timeout::timeout(2) { lock.flock(File::LOCK_EX) }
      input = if File.exists?(@datafile)
        contents = File.read(@datafile)
        contents.strip.empty? ? [] : JSON.parse(contents)
      else
        []
      end
      output = yield input
      File.write(@datafile, output.to_json)
    end
  end
end

module CloudIDType
  STEMCELL = :stemcell
  VM = :vm
end
