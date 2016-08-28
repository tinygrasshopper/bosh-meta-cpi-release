require_relative '../lib/cloud_id'
require_relative '../lib/meta_error'
require_relative '../lib/meta_cpi'
require 'tempfile'
require 'json'
require 'fileutils'

class MockExecutable
  def initialize(expected_return_value)
    @executable_file = Tempfile.new('')
    @capture_file = Tempfile.new('')
    returns(expected_return_value)
    # returns(expected_return_value)
    # File.chmod(0744,@executable_file.path)
  end
  def returns(expected_return_value)
    new_file= Tempfile.new('')
    @executable_file.truncate(0)
    new_file.write("#!/usr/bin/env bash
read input
echo $input > #{@capture_file.path}
echo '#{expected_return_value}'
")
    new_file.flush
    File.chmod(0744,new_file.path)
    FileUtils.mv new_file.path, @executable_file.path
  end

  def called_with
    @capture_file.read
  end

  def path
    @executable_file.path
  end

  def cleanup
    [@executable_file, @capture_file].each(&:unlink)
  end
end
