require 'spec_helper'

describe MetaCPI do
  let(:log_file) { Tempfile.new('') }
  let(:state_file) { Tempfile.new('') }
  let(:lock_file) { Tempfile.new('') }
  let(:default_cpi) { :aws }


  subject { MetaCPI.new(log_file: log_file.path, default_cpi: default_cpi, available_cpis: available_cpis, state_file: state_file.path, lock_file: lock_file.path) }

  after(:each) do
    log_file.unlink
    state_file.unlink
  end

  context 'upload stemcells' do
    context 'aws stemcell' do
      let(:aws_cpi) { MockExecutable.new('{"result":"c3be6b65-3b01-4d22-77df-5cce09aa3d0c","error":null,"log":""}') }
      let(:available_cpis) { {aws: aws_cpi.path} }
      after(:each) do
        aws_cpi.cleanup
      end
      it 'invokes the aws cpi for stemcell' do
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160811-8042-j83kkx/image",{"name":"bosh-aws-xen-hvm-ubuntu-trusty-go_agent","version":"3262.5","infrastructure":"aws","hypervisor":"xen","disk":3072,"disk_format":"raw","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1","ami":{"eu-central-1":"ami-e16c9b8e","sa-east-1":"ami-b92eb9d5","ap-northeast-1":"ami-4e9f592f","us-west-1":"ami-eae7a78a","eu-west-1":"ami-636a0310","us-west-2":"ami-20559c40","ap-northeast-2":"ami-4a21eb24","ap-southeast-1":"ami-99cc12fa","ap-southeast-2":"ami-c16450a2","us-east-1":"ami-3b2cbf2c"}}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(aws_cpi.called_with.strip).to eq(cmd)
        expect(output.strip).to eq('{"result":"c3be6b65-3b01-4d22-77df-5cce09aa3d0c","error":null,"log":""}')
      end

      it 'saves cloud_id of the stemcell into state' do
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160811-8042-j83kkx/image",{"name":"bosh-aws-xen-hvm-ubuntu-trusty-go_agent","version":"3262.5","infrastructure":"aws","hypervisor":"xen","disk":3072,"disk_format":"raw","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1","ami":{"eu-central-1":"ami-e16c9b8e","sa-east-1":"ami-b92eb9d5","ap-northeast-1":"ami-4e9f592f","us-west-1":"ami-eae7a78a","eu-west-1":"ami-636a0310","us-west-2":"ami-20559c40","ap-northeast-2":"ami-4a21eb24","ap-southeast-1":"ami-99cc12fa","ap-southeast-2":"ami-c16450a2","us-east-1":"ami-3b2cbf2c"}}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(JSON.parse(state_file.read)).to eq([{"id" => "c3be6b65-3b01-4d22-77df-5cce09aa3d0c", "type" => "stemcell", "cpi" => "aws"}])
      end
    end

    context "error uploading stemcell" do
      let(:aws_cpi) { MockExecutable.new('{"result":"c3be6b65-3b01-4d22-77df-5cce09aa3d0c","error":"some error","log":""}') }
      let(:available_cpis) { {aws: aws_cpi.path} }

      it "dosen't save the id" do
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160811-8042-j83kkx/image",{"name":"bosh-aws-xen-hvm-ubuntu-trusty-go_agent","version":"3262.5","infrastructure":"aws","hypervisor":"xen","disk":3072,"disk_format":"raw","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1","ami":{"eu-central-1":"ami-e16c9b8e","sa-east-1":"ami-b92eb9d5","ap-northeast-1":"ami-4e9f592f","us-west-1":"ami-eae7a78a","eu-west-1":"ami-636a0310","us-west-2":"ami-20559c40","ap-northeast-2":"ami-4a21eb24","ap-southeast-1":"ami-99cc12fa","ap-southeast-2":"ami-c16450a2","us-east-1":"ami-3b2cbf2c"}}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(state_file.read).to eq("")
      end
    end


    context 'warden stemcell' do
      let(:warden_cpi_output){'{"result":"i-0fce66f99336acfd3","error":null,"log":""}'}
      let(:aws_cpi) { MockExecutable.new("aws_cpi_output") }
      let(:warden_cpi) { MockExecutable.new(warden_cpi_output) }
      let(:available_cpis) { {aws: aws_cpi.path, warden: warden_cpi.path} }
      after(:each) do
        aws_cpi.cleanup
        warden_cpi.cleanup
      end
      it 'invokes the warden cpi for stemcell' do
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160813-22154-cgsqlx/image",{"name":"bosh-warden-boshlite-ubuntu-trusty-go_agent","version":"3262.2","infrastructure":"warden","hypervisor":"boshlite","disk":2048,"disk_format":"files","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1"}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(warden_cpi.called_with.strip).to eq(cmd)
        expect(output.strip).to eq(warden_cpi_output)
      end
    end

    context 'cpi not provided' do
      let(:aws_cpi) { MockExecutable.new("aws_cpi_output") }
      let(:available_cpis) { {aws: aws_cpi.path} }
      after(:each) do
        aws_cpi.cleanup
      end
      it 'returns an error' do
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160813-22154-cgsqlx/image",{"name":"bosh-warden-boshlite-ubuntu-trusty-go_agent","version":"3262.2","infrastructure":"warden","hypervisor":"boshlite","disk":2048,"disk_format":"files","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1"}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(output.strip).to eq('{"result":null,"error":{"type":"Unknown","message":"unknown cpi warden","ok_to_retry":false},"log":[]}')
      end
    end
  end

  context 'create_vm' do
    context 'networks' do
      let(:aws_cpi) { MockExecutable.new('') }
      let(:warden_cpi) { MockExecutable.new("") }
      let(:available_cpis) { {aws: aws_cpi.path, warden: warden_cpi.path} }
      after(:each) do
        aws_cpi.cleanup
      end

      it 'assigns the dynamic network config for the cpi' do
        aws_cpi.returns('{"result":"ami-83c8bef0","error":null,"log":""}')
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160811-8042-j83kkx/image",{"name":"bosh-aws-xen-hvm-ubuntu-trusty-go_agent","version":"3262.5","infrastructure":"aws","hypervisor":"xen","disk":3072,"disk_format":"raw","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1","ami":{"eu-central-1":"ami-e16c9b8e","sa-east-1":"ami-b92eb9d5","ap-northeast-1":"ami-4e9f592f","us-west-1":"ami-eae7a78a","eu-west-1":"ami-636a0310","us-west-2":"ami-20559c40","ap-northeast-2":"ami-4a21eb24","ap-southeast-1":"ami-99cc12fa","ap-southeast-2":"ami-c16450a2","us-east-1":"ami-3b2cbf2c"}}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)
        expect(output.strip).to eq('{"result":"ami-83c8bef0","error":null,"log":""}')

        cmd = '{"method":"create_vm","arguments":["c712902c-a3f0-4768-a392-13ed1389aff8","ami-83c8bef0",{"cloud_provider":"aws","instance_type":"t2.micro","ephemeral_disk":{"size":3000,"type":"gp2"}},{"compilation":{"type":"dynamic","cloud_properties":{"meta":{"aws":{"dns":["10.0.16.2"],"subnet":"subnet-bb1884df"}}},"default":["dns","gateway"]}},[],{}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        aws_cpi.returns('{"result":"i-0fce66f99336acfd3","error":null,"log":""}')

        output = subject.run(cmd)
        expect(output.strip).to eq('{"result":"i-0fce66f99336acfd3","error":null,"log":""}')
        expect(JSON.parse(aws_cpi.called_with)).to eq({
          "method"=>"create_vm",
          "arguments"=> [
            "c712902c-a3f0-4768-a392-13ed1389aff8",
            "ami-83c8bef0",
            {"cloud_provider"=>"aws",
             "instance_type"=>"t2.micro",
             "ephemeral_disk"=>{"size"=>3000, "type"=>"gp2"}
            },
            {"compilation"=>
              {"type"=>"dynamic",
               "dns"=>["10.0.16.2"],
               "cloud_properties"=>
                 {"dns"=>["10.0.16.2"],
                  "subnet"=>"subnet-bb1884df",
                  "meta"=>{"aws"=>{"dns"=>["10.0.16.2"],
                                   "subnet"=>"subnet-bb1884df"}
                          }
                 },
                 "default"=>["dns", "gateway"]
              }
            },
            [],
            {}], "context"=>{"director_uuid"=>"a5124231-2459-4774-b27e-3c45d3d5bb49"}})

        expect(JSON.parse(state_file.read)).to eq([
          {"id" => "ami-83c8bef0", "type" => "stemcell", "cpi" => "aws"},
          {"id" => "i-0fce66f99336acfd3", "type" => "vm", "cpi" => "aws"}
        ])
      end
    end
  end
  # {"method":"set_vm_metadata","arguments":["i-016ba2cc5c6429f8c",{"director":"bosh-bosh-bosh","deployment":"red","id":"b9c2cd5c-7492-4d6d-a30b-ed987d24d307","job":"nothing","index":"0","name":"nothing/b9c2cd5c-7492-4d6d-a30b-ed987d24d307","created_at":"2016-08-16T00:17:16Z"}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}
  # {"method":"delete_stemcell","arguments":["ami-83c8bef0"],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}
  # {"method":"delete_vm","arguments":["i-0f50317068e88a9e1"],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}
  context 'delete stemcells' do
    context 'calls the cpi recorded' do
      let(:aws_cpi) { MockExecutable.new("") }
      let(:warden_cpi) { MockExecutable.new("") }
      let(:available_cpis) { {warden: warden_cpi.path,aws: aws_cpi.path, } }
      after(:each) do
        aws_cpi.cleanup
        warden_cpi.cleanup
      end
      it 'returns an error' do
        warden_cpi.returns('{"result":"ami-83c8bef0","error":null,"log":""}')
        cmd = '{"method":"create_stemcell","arguments":["/var/vcap/data/tmp/director/stemcell20160811-8042-j83kkx/image",{"name":"bosh-aws-xen-hvm-ubuntu-trusty-go_agent","version":"3262.5","infrastructure":"warden","hypervisor":"xen","disk":3072,"disk_format":"raw","container_format":"bare","os_type":"linux","os_distro":"ubuntu","architecture":"x86_64","root_device_name":"/dev/sda1","ami":{"eu-central-1":"ami-e16c9b8e","sa-east-1":"ami-b92eb9d5","ap-northeast-1":"ami-4e9f592f","us-west-1":"ami-eae7a78a","eu-west-1":"ami-636a0310","us-west-2":"ami-20559c40","ap-northeast-2":"ami-4a21eb24","ap-southeast-1":"ami-99cc12fa","ap-southeast-2":"ami-c16450a2","us-east-1":"ami-3b2cbf2c"}}],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)
        expect(output.strip).to eq('{"result":"ami-83c8bef0","error":null,"log":""}')
        expect(JSON.parse(state_file.read)).to eq([{"id" => "ami-83c8bef0", "type" => "stemcell", "cpi" => "warden"}])

        warden_cpi.returns '{"result":true,"error":null,"log":""}'
        cmd = '{"method":"delete_stemcell","arguments":["ami-83c8bef0"],"context":{"director_uuid":"a5124231-2459-4774-b27e-3c45d3d5bb49"}}'
        output = subject.run(cmd)

        expect(output.strip).to eq('{"result":true,"error":null,"log":""}')
        expect(warden_cpi.called_with.strip).to eq(cmd)
      end
    end
  end
end
