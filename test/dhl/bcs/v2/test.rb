require 'test_helper'

module Dhl::Bcs::V2
  class Test < Minitest::Test

    def setup
      config = { user: '2222222222_01', signature: 'pass', ekp: '2222222222', participation_number: '01', api_user: 'test', api_pwd: 'test' }
      options = { test: true, log: true}
      @client = Dhl::Bcs.client(config, options)
    end

    def test_create_shipment_order_request
      # WebMock.allow_net_connect!
      stub_and_check(file_prefix: 'create_shipment_order_international_packet') do
        result = @client.create_shipment_order(valid_shipment_international_packet)
        assert_equal(
          [
            {
              status: { status_code: '0', status_text: 'ok', status_message: 'Der Webservice wurde ohne Fehler ausgeführt.' },
              shipment_number: '22222222201019582121',
              label_url: 'https://cig.dhl.de/gkvlabel/SANDBOX/dhl-vls/gw/shpmntws/printShipment?token=JD7HKktuvugIFEkhSvCfbEz4J8Ah0dkcVuw4PzBGRyRnW%2FwEPAwfytLtb31e7gMDsSX32%2BEB5exp8nNPs%2FhJSQ%3D%3D',
              export_label_url: 'https://cig.dhl.de/gkvlabel/SANDBOX/dhl-vls/gw/shpmntws/printShipment?token=Vfov%2BMinVhMH6nQVfvSCmNUSRNnaQNHKPaiLiWtXsqm%2BENCM6wnStB2C44rl6BEmSxbrPeaTQwBhoHBr802FnuftGVJ9uVM0C0ztLpxNfyc%3D',
            }
          ], result)
      end
    end

    private

    def valid_shipment_international_packet
      Dhl::Bcs.build_shipment(
        shipper: {
          name: 'Christoph Wagner',
          company: 'webit!',
          street_name: 'Schandauer Straße',
          street_number: '34',
          zip: '01309',
          city: 'Dresden',
          country_code: 'DE',
          email: 'wagner@webit.de'
        },
        receiver: {
          name: 'Jane Doe',
          street_name: 'Bleicherweg',
          street_number: '5',
          zip: '8001',
          city: 'Zürich',
          country_code: 'CH',
          email: 'jane.doe@example.com'
        },
        weight: 3.5,
        product: 'V53WPAK',
        shipment_date: Date.new(2018, 4, 18),
        export_document: {
          invoice_number: 12345678,
          export_type: 'OTHER',
          export_type_description: 'Permanent',
          terms_of_trade: 'DDP',
          place_of_commital: 'Bonn',
          permit_number: 1234,
          attestation_number: 12345678,
          with_electronic_export_notification: true,
          export_doc_positions: 
          [{
            description: 'ExportPositionOne',
            country_code_origin: 'CN',
            customs_tariff_number: 12345678,
            amount: 1,
            net_weight_in_kg: 0.2,
            customs_value: 24.96

          },
          {
            description: 'ExportPositionTwo',
            country_code_origin: 'CN',
            customs_tariff_number: 12345678,
            amount: 1,
            net_weight_in_kg: 0.4,
            customs_value: 99.90

          }
          ]
        }

      )
    end

    def stub_and_check(method: :post, url: 'https://cig.dhl.de/services/sandbox/soap', file_prefix: '')
      stub_request(method, url).to_return(status: 200, body: File.read("test/stubs/#{file_prefix}_response.xml"))

      # use Nokogiri to remove all whitespaces between the xml tags
      request_xml =
        Nokogiri::XML.parse(File.read("test/stubs/#{file_prefix}_request.xml"), &:noblanks).
        to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML).sub("\n", '').strip

        yield
        assert_requested method, url, body: request_xml
    end

  end
end
