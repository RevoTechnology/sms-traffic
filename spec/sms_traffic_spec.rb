require 'spec_helper'

RSpec.describe Smstraffic::SMS do
  before(:all) do
    described_class.settings = {
      login: 'mylogin',
      password: 'mypassword',
      server: 'sms_server.com',
      translit: true,
      routeGroupId: 'abcdef'
    }
  end

  describe '.status' do
    subject { described_class.status(message_id) }

    let(:message_id) { '1234567890' }
    let(:status_url) { "https://sms_server.com/smartdelivery-in/multi.php?login=mylogin&password=mypassword&operation=status&sms_id=#{message_id}" }

    context 'server responds with XML' do
      before { stub_request(:get, status_url).to_return(body: xml_response) }

      context 'OK' do
        let(:xml_response) do
          <<~BODY
            <sd-reply>
              <result>OK</result>
              <msg-info>
                <submition_date>2017-02-22 12:57:13</submition_date>
                <status>NOT_ROUTED</status>
                <channel-info>
                  <parts_count>1</parts_count>
                  <status>SENT</status>
                  <parts_dlv_count>0</parts_dlv_count>
                  <channel>sms</channel>
                  <sent_date>2017-02-22 12:57:13</sent_date>
                </channel-info>
                <last_update_status>2017-02-22 12:58:14</last_update_status>
                <id>#{message_id}</id>
              </msg-info>
              <code>0</code>
            </sd-reply>
          BODY
        end

        it { is_expected.to eq(["OK", "0", "SENT"]) }
      end

      context 'Non-existent message ID' do
        let(:xml_response) do
          <<~BODY
            <sd-reply>
              <result>OK</result>
              <msg-info>
                <description>message info is not available</description>
                <id>#{message_id}</id>
              </msg-info>
              <code>0</code>
            </sd-reply>
          BODY
        end

        it { is_expected.to eq(["OK", "0", nil]) }
      end

      context 'Wrong login/password' do
        let(:xml_response) do
          <<~BODY
            <sd-reply>
              <result>ERROR</result>
              <description>Wrong login or password</description>
              <code>411</code>
            </sd-reply>
          BODY
        end

        it { is_expected.to eq(["ERROR", "411", nil]) }
      end

      context 'Message ID of wrong format' do
        let(:xml_response) do
          <<~BODY
            <reply>
              <code>704</code>
              <description>Invalid individual_messages value</description>
              <result>ERROR</result>
            </reply>
          BODY
        end

        it { is_expected.to eq(["ERROR", "704", nil]) }
      end

      context 'Invalid request params' do
        let(:xml_response) do
          <<~BODY
            <sd-reply>
              <result>ERROR</result>
              <description>Incompatible query parameters</description>
              <code>404</code>
            </sd-reply>
          BODY
        end

        it { is_expected.to eq(["ERROR", "404", nil]) }
      end
    end

    context 'HTTP error 500' do
      before { stub_request(:get, status_url).to_return(status: 500) }

      it 'fails with proper exception' do
        expect { subject }.to raise_error(Smstraffic::SMS::RequestFailure)
      end
    end

    context 'HTTP timeout' do
      before { stub_request(:get, status_url).to_timeout }

      it 'fails with proper exception' do
        expect { subject }.to raise_error(Smstraffic::SMS::RequestFailure)
      end
    end
  end
end
