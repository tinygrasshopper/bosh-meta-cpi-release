require 'json'

class MetaCPI
  def initialize(params)
    @params = params
    @repository = CloudIDRepository.new(params[:state_file])
  end

  def run(input)
    log "META INPUT: #{input}"
    cpi_request = JSON.parse(input)
    method = cpi_request["method"].to_sym
    parameters = cpi_request["arguments"]
    output = if self.respond_to?(method, true)
      self.send(method, parameters, input)
    else
      exec_with_cpi(default_cpi, input)
    end
    log "META OUTPUT: #{output}"
    output
  rescue => e
    log "META OUTPUT ERROR: #{e.to_s}"
    e.to_s
  end

  private

  def create_stemcell(parameters, input)
    cpi = parameters[1]["infrastructure"].to_sym
    output = exec_with_cpi(cpi_for(cpi), input)
    parsed_json = JSON.parse(output)
    @repository.append({"id" => parsed_json["result"], "type" => CloudIDType::STEMCELL, "cpi" => cpi})
    output
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
    log "CPI INPUT: #{input}"
    output = `echo '#{input}' | env -i #{cpi}`
    log "CPI OUTPUT: #{output}"
    output
  end
end
