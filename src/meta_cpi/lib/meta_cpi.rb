require 'json'

class MetaCPI
  def initialize(params)
    @params = params
    @repository = CloudIDRepository.new(params[:state_file], params[:lock_file])
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
  rescue MetaError => e
    log "META OUTPUT ERROR: #{e.to_s}"
    e.response
  end

  private

  def create_stemcell(parameters, input)
    cpi = parameters[1]["infrastructure"].to_sym
    output = exec_with_cpi(cpi_for(cpi), input)
    parsed_json = JSON.parse(output)
    if parsed_json["error"].nil?
      @repository.append({"id" => parsed_json["result"], "type" => CloudIDType::STEMCELL, "cpi" => cpi})
    end
    output
  end

  def create_vm(parameters, input)
    stemcell = parameters[1]
    cloud_id = @repository.find(stemcell, CloudIDType::STEMCELL)
    if cloud_id.nil?
      raise MetaError.new("meta cpi dosen't know about stemcell #{stemcell}")
    end
    cpi = cloud_id["cpi"].to_sym
    input_json = JSON.parse(input)
    modified_input = inject_networks_from_meta_config(input_json,cpi)
    output = exec_with_cpi(cpi_for(cpi), modified_input.to_json)
    parsed_json = JSON.parse(output)
    if parsed_json["error"].nil?
      @repository.append({"id" => parsed_json["result"], "type" => CloudIDType::VM, "cpi" => cpi})
    end
    output
  end

  def default_cpi
    cpi_for(@params[:default_cpi])
  end

  def cpi_for(name)
    if @params[:available_cpis][name].nil?
      raise MetaError.new("unknown cpi #{name}")
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

  def inject_networks_from_meta_config(input,cpi)
    networks = input["arguments"][3]
    networks.each do |name, network|
      config_for_cpi = network["cloud_properties"]["meta"][cpi.to_s]
      if config_for_cpi
        network["dns"] = config_for_cpi["dns"] if config_for_cpi["dns"]
        network["cloud_properties"].merge!(config_for_cpi)
      end
    end
    input
  end

  def exec_with_cpi(cpi, input)
    log "USING CPI: #{cpi}"
    log "CPI INPUT: #{input}"
    output = `echo '#{input}' | env -i #{cpi}`
    log "CPI OUTPUT: #{output}"
    output
  end
end
