require 'net/http'
require 'openssl'
require 'uri'
require 'russian'

module Smstraffic
  class SMS

    attr_accessor :phone, :subject, :message
    attr_reader :id, :status, :errors

    def initialize(phone, subject, message, translit=nil)
      @phone = phone.to_s.length == 10 ? "7#{phone}".to_i : phone
      @subject = subject
      @message = message
      @status = 'not-sent'
      @translit = translit.nil? ? @@translit : translit
      @errors = []

      validate!
    end

    def self.settings=(settings={})
      @@login = settings[:login]
      @@password = settings[:password]
      @@server = settings[:server]
      @@routeGroupId = settings[:routeGroupId]
      @@port = 80
      @@ssl_port = 443
      @@ssl = !settings[:ssl].nil? ? settings[:ssl] : true # connect using ssl by default
      @@translit = !settings[:translit].nil? ? settings[:translit] : false # use translit or not
      validate_settings!
    end

    def self.ssl=(flag)
      @@ssl = flag
    end

    def self.ssl
      @@ssl
    end

    # => SMS send status codes:
    #    401 - Не указан логин
    #    402 - Не указан пароль
    #    403 - Не указаны номера телефонов
    #    404 - Несовместимые параметры запроса
    #    405 - Не указан текст сообщения
    #    406 - wap push сообщение слишком длинное
    #    407 - Не указан ни один телефон
    #    408 - Неподдерживаемый тип сообщения: "тип_сообщения"
    #    409 - Не указан udh
    #    410 - Автоматическая разбивка бинарных сообщений не поддерживается
    #    411 - Неверный логин или пароль
    #    412 - Неверный IP
    #    413 - Такой группы не существует: "имя_группы"
    #    414 - В группе нет ни одного телефона
    #    415 - Недостаточно средств
    #    416 - Неверный формат даты начала рассылки: "дата_старта_рассылки"
    #    417 - Дата начала рассылки "дата_старта_рассылки" находится в прошлом
    #    418 - Идентификаторы не предоставляются для отложенных сообщений
    #    419 - Вам не разрешено использовать данный маршрут
    #    420 - Сообщение "текст_сообщения" слишком длинное
    #    421 - Имя отправителя слишком длинное
    #    422 - Не указан телефон в строке "номер_строки": "строка"
    #    423 - Пустое сообщение для телефона "номер_телефона"
    #    424 - Сообщение "текст_сообщения" для телефона "номер_телефона" слишком длинное
    #    425 - Номер телефона "номер_телефона" слишком короткий. Ни одно сообщение не было отправлено
    #    426 - Номер телефона "номер_телефона" слишком длинный. Ни одно сообщение не было отправлено
    #    427 - "номер_телефона": неверная длина номера телефона. Ни одно сообщение не было отправлено
    #    428 - "номер_телефона": неверный формат номера телефона. Ни одно сообщение не было отправлено
    #    429 - "номер_телефона": неподдерживаемый оператор. Ни одно сообщение не было отправлено
    #    430 - "номер_телефона": неверный номер телефона. Ни одно сообщение не было отправлено
    #    431 - Телефон +"номер_телефона" не подписан на рассылку. Ни одно сообщение не было отправлено
    #    432 - Заблокированный номер телефона: "номер_телефона". Ни одно сообщение не было отправлено
    #    433 - Не указан параметр sms_id
    #    434 - Такого сообщения нет или оно вам не принадлежит
    #    435 - Невозможно отменить сообщение "sms_id"
    #    436 - Отправитель "отправитель" запрещен
    #    437 - Сообщение превышает 160 символов после транслитерации "текст_сообщения"
    #    438 - В сообщении найден шаблон, но не задана ни одна группа
    #    439 - Вы не можете отправлять SMS­сообщения через HTTP
    #    440 - Параметр "phones" не задан или задан некорректно
    #    441 - Неверный формат файла параметров
    #    442 - Неверное число параметров
    #    501 - Время окончания рассылки в прошлом
    #    502 - Время начала рассылки больше времени окончания рассылки
    #    1000 - Временные проблемы на сервере

    def send
      #return stubbed_send if (defined?(Rails) && !Rails.env.production?)
      self.class.establish_connection.start do |http|
        request = Net::HTTP::Get.new(send_url)
        response = http.request(request)
        body = response.body
        hash = Hash.from_xml(Nokogiri::XML(body).to_s)['reply']
        result = hash['result']
        if result == 'OK'
          @status = 'sent'
          @id = hash['message_infos']['message_info']['sms_id']
          true
        else
          @errors << "#{result}: code: #{hash['code']}, description: #{hash['description']}"
          false
        end
      end
    end

    # => SMS status codes:
    #            СТАТУС              ТИП
    #    'Нет статуса (blank)' - Промежуточный
    #    'Acceptd'             - Промежуточный
    #    'Delivered'           - Окончательный
    #    'Non Delivered' -     - Окончательный
    #    'Rejected'            - Окончательный
    #    'Expired'             - Окончательный
    #    'Deleted'             - Окончательный
    #    'Unknown status'      - Окончательный


    def self.status(id)
      establish_connection.start do |http|
        request = Net::HTTP::Get.new(status_url id)
        response = http.request(request)
        body = response.body
        hash = Hash.from_xml(Nokogiri::XML(body).to_s)['reply']
        hash['status'] || hash['error'] #status or error
      end
    end

    def update_status
      return @status if @id.nil?
      code, status = self.class.status(@id)
      return code unless code == 'ok'
      @status = status
    end

    def validate!
      raise ArgumentError, "Phone should be assigned to #{self.class}." if @phone.nil?
      raise ArgumentError, "Phone number should contain only numbers. Minimum length is 11. #{@phone.inspect} is given." unless "#{@phone}" =~ /^[0-9]{11}$/
      raise ArgumentError, "Subject should be assigned to #{self.class}." if @subject.nil?
      raise ArgumentError, "Message should be assigned to #{self.class}." if @message.nil?
    end

    private

    def self.establish_connection
      port = @@ssl ? @@ssl_port : @@port
      http = Net::HTTP.new(@@server, port)
      http.use_ssl = @@ssl
      http
    end

    def self.validate_settings!
      raise ArgumentError, "Login should be defined for #{self}." if @@login.nil?
      raise ArgumentError, "Password should be defined for #{self}." if @@password.nil?
      raise ArgumentError, "Server should be defined for #{self}." if @@server.nil?
    end

    def send_url
      message, rus = @translit ? [Russian.translit(@message), 0] : [@message, 1]
      message = URI.encode(message)
      subject = URI.encode(@subject)
      "/smartdelivery-in/multi.php?login=#{@@login}&password=#{@@password}&phones=#{@phone}&message=#{message}&want_sms_ids=1&routeGroupId=#{@@routeGroupId}&rus=#{rus}&originator=#{subject}"
    end

    def self.status_url(msg_id)
      "/smartdelivery-in/multi.php?login=#{@@login}&password=#{@@password}&operation=status&sms_id=#{msg_id}"
    end

  end
end
