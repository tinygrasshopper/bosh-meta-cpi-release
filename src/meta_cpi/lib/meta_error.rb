class MetaError < StandardError
  attr_reader :message
  def initialize(message)
    @message = message
  end

  def response
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
end
