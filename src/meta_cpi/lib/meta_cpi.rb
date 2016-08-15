require 'json'

class MetaCPI
  def initialize(params)
    @params = params
  end

  def run(input)
    log "INPUT: #{input}"
    cpi_request = JSON.parse(input)
    method = cpi_request["method"].to_sym
    parameters = cpi_request["arguments"]
    if self.respond_to?(method, true)
      self.send(method, parameters, input)
    else
      exec_with_cpi(default_cpi, input)
    end
  rescue => e
    e.to_s
  end

  private

  def create_stemcell(parameters, input)
    exec_with_cpi(cpi_for(parameters[1]["infrastructure"].to_sym), input)
  end

  def default_cpi
    cpi_for(@params[:default_cpi])
  end

  def cpi_for(name)
    if @params[:available_cpis][name] == nil
      raise error("unknown cpi #{name}")
    else
      @params[:available_cpis][name]
    end
  end

  def aws_cpi
    cpi_for(:aws)
  end

  def warden_cpi
    cpi_for(:warden)
  end

  def log message
    `echo '#{message}' >> #{log_file}`
  end

  def log_file
    @params[:log_file]
  end

  def error message
    {
      result: nil,
      error: {
        type: 'Unknown',
        message: message,
        ok_to_retry: false,
      },
      log: [],
    }.to_json
  end

  def exec_with_cpi(cpi, input)
    log "USING CPI: #{cpi}"
    output = `echo '#{input}' | env -i #{cpi}`
    log "OUTPUT: #{output}"
    output
  end
end
