require 'spec_helper'

describe "sample-app::default" do

  before do
    stub_data_bag("yummy").and_return([])
    stub_command("/usr/sbin/apache2 -t").and_return("Syntax OK")
    stub_command("/usr/sbin/httpd -t").and_return("Syntax OK")
  end

  context "on ubuntu systems" do
    subject { chef_run(platform: 'ubuntu', version: '12.04') }
    it { should install_package 'apache2' }
    it { should start_service 'apache2' }
  end

  context "on centos systems" do
    subject { chef_run(platform: 'centos', version: '6.3') }
    it { should install_package 'httpd' }
    it { should start_service 'httpd' }
  end

  context "default 'words_of_wisdom'" do
    subject { chef_run }
    it { should render_file("/var/www/sample.html").with_content("I can haz cats!") }
  end

  context "when 'words_of_wisdom' are set" do
    subject { chef_run {
      node.set['sample_app']['words_of_wisdom'] = "no cats today :-("
    }}
    it { should render_file("/var/www/sample.html").with_content("no cats today :-(") }
  end

  context "with data bag items" do
    before do
      stub_data_bag("yummy").and_return(["ananas"])
      stub_data_bag_item("yummy", "ananas").and_return(id: "ananas", desc: 'yellow & sweet')
    end
    subject { chef_run }
    it { should render_file("/var/www/sample.html").with_content("<li>ananas: yellow & sweet</li>") }
  end

  context "when data_bag_path is invalid" do
    before do
      stub_data_bag("yummy").and_raise(Chef::Exceptions::InvalidDataBagPath)
    end
    subject { chef_run }
    it { should write_log("can not load data_bag: Chef::Exceptions::InvalidDataBagPath") }
    it { should render_file("/var/www/sample.html").with_content(%r{<ul>\s*</ul>}) }
  end
end
