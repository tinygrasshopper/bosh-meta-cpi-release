require_relative '../lib/meta_cpi'
require 'tempfile'
require 'json'

class MockExecutable
  def initialize(expected_return_value)
    @executable_file = Tempfile.new('')
    @capture_file = Tempfile.new('')
    @executable_file.write("#!/usr/bin/env bash
read input
echo $input > #{@capture_file.path}
echo #{expected_return_value}
")
  @executable_file.close
  File.chmod(0744,@executable_file.path)
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
