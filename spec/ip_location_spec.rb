require "spec_helper"
require "chef/node"
require "libraries/ip_location"

describe RCB do
  let(:library) { Object.new.extend(RCB) }
  let(:node) { Chef::Node.new }

  describe "#osops_search" do
    let(:current_node) do
      node = Chef::Node.new
      node.set["roles"] = []
      node.set["recipes"] = []
      node.set["tags"] = []
      node.stub("name").and_return("current_node")
      node
    end
    let(:query) { double(Chef::Search::Query) }
    let(:result_node) do
      node = Chef::Node.new
      node.set["roles"] = []
      node.set["recipes"] = []
      node.set["tags"] = []
      node.stub("name").and_return("result_node")
      node
    end
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)

      library.stub("node").and_return(current_node)
    end

    context "with defaults" do
      it "returns one result from roles" do
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([results, nil, nil])

        library.osops_search("term").should eq result_node
      end

      it "returns one result from recipes if roles returns nothing" do
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([[], nil, nil])

        query.should_receive("search").
          with(:node, "recipes:term AND chef_environment:_default").
          and_return([results, nil, nil])

        library.osops_search("term").should eq result_node
      end

      it "returns current node w/o searching if node has role" do
        current_node.set["roles"] = ["term"]
        results << result_node

        query.should_not_receive("search")

        library.osops_search("term").should eq current_node
      end

      it "returns current node w/o searching recipes if node has recipe" do
        current_node.set["recipes"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([[], nil, nil])

        library.osops_search("term").should eq current_node
      end
    end

    context "with include_me param disabled" do
      it "ignores current node w/o searching if node has role" do
        current_node.set["roles"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([results, nil, nil])

        library.osops_search("term", :one, false).should eq result_node
      end
    end

    context "with include_me option disabled" do
      it "ignores current node w/o searching if node has role" do
        current_node.set["roles"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([results, nil, nil])

        library.osops_search("term", :one, true, [:role, :recipe], nil, nil, :include_me => false).should eq result_node
      end
    end

    context "with one_or_all set to :all" do
      it "returns all results" do
        current_node.set["roles"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([results, nil, nil])

        query.should_receive("search").
          with(:node, "recipes:term AND chef_environment:_default").
          and_return([[], nil, nil])

        library.osops_search("term", :all).should eq [current_node, result_node]
      end
    end

    context "with one_or_all options set to :all" do
      it "returns all results" do
        current_node.set["roles"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "roles:term AND chef_environment:_default").
          and_return([results, nil, nil])

        query.should_receive("search").
          with(:node, "recipes:term AND chef_environment:_default").
          and_return([[], nil, nil])

        library.osops_search("term", :one, true, [:role, :recipe], nil, nil, :one_or_all => :all).should eq [current_node, result_node]
      end
    end

    context "with order set to tags" do
      it "searches tags instead" do
        current_node.set["tags"] = ["term"]
        results << result_node

        query.should_receive("search").
          with(:node, "tags:term AND chef_environment:_default").
          and_return([results, nil, nil])

        library.osops_search("term", :all, true, [:tag]).should eq [current_node, result_node]
      end
    end
  end

  describe "#get_if_ip_for_net" do
    context "with a Chef::Node" do
      before do
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" },
          "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
        }

        library.stub("node").and_return(node)
      end

      it "returns 0.0.0.0 for all" do
        library.get_if_ip_for_net("all").should eq "0.0.0.0"
      end

      it "returns 127.0.0.1 for localhost" do
        library.get_if_ip_for_net("localhost").should eq "127.0.0.1"
      end

      it "doesn't log errors when option set" do
        node.set["osops"] = {}

        Chef::Log.should_not_receive("error").with(/can't find network/i)

        expect { library.get_if_ip_for_net("nonet", nil, :log_errors => false) }.
          to raise_error(/can't find network/i)
      end

      it "logs and raises an error for no networks" do
        node.set["osops"] = {}

        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_if_ip_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "logs and raises an error for a missing network" do
        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_if_ip_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "returns an interface and ip for matching inet4 network" do
        node.set["osops_networks"]["network"] = "172.16.0.0/16"

        library.get_if_ip_for_net("network").should eq ["eth0", "172.16.10.1"]
      end

      it "returns an interface and ip for matching inet6 network" do
        node.set["osops_networks"]["network"] =
          "21DA:00D3:0000:2F3B:02AA:00FF::/32"

        library.get_if_ip_for_net("network").
          should eq ["eth0", "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"]
      end

      it "raises an exception if no matching network is found" do
        node.set["osops_networks"]["network"] = "10.10.0.0/16"

        Chef::Log.should_receive("error").with(/can't find address on network/i)

        expect { library.get_if_ip_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end
    end
  end

  describe "#get_if_for_net" do
    context "with a Chef::Node" do
      before do
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" },
          "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
        }

        library.stub("node").and_return(node)
      end

      it "returns 0.0.0.0 for all" do
        library.get_if_for_net("all").should eq "0.0.0.0"
      end

      it "returns 127.0.0.1 for localhost" do
        library.get_if_for_net("localhost").should eq "127.0.0.1"
      end

      it "logs and raises an error for no networks" do
        node.set["osops"] = {}

        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_if_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "logs and raises an error for a missing network" do
        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_if_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "returns an interface and ip for matching inet4 network" do
        node.set["osops_networks"]["network"] = "172.16.0.0/16"

        library.get_if_for_net("network").should eq "eth0"
      end

      it "returns an interface and ip for matching inet6 network" do
        node.set["osops_networks"]["network"] =
          "21DA:00D3:0000:2F3B:02AA:00FF::/32"

        library.get_if_for_net("network").should eq "eth0"
      end

      it "raises an exception if no matching network is found" do
        node.set["osops_networks"]["network"] = "10.10.0.0/16"

        Chef::Log.should_receive("error").with(/can't find address on network/i)

        expect { library.get_if_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end
    end
  end

  describe "#get_ip_for_net" do
    context "with a Chef::Node" do
      let(:node) { Chef::Node.new }

      before do
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" },
          "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
        }

        library.stub("node").and_return(node)
      end

      it "logs and raises an error for no networks" do
        node.set["osops"] = {}

        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_ip_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "logs and raises an error for a missing network" do
        Chef::Log.should_receive("error").with(/can't find network/i)

        expect { library.get_ip_for_net("nonet") }.
          to raise_error(/can't find network/i)
      end

      it "skips an interface and ip for matching inet4 ip/32" do
        node.set["network"]["interfaces"]["eth0"]["addresses"]["172.16.10.1"]["prefixlen"] = "32"
        node.set["osops_networks"]["network"] = "172.16.0.0/16"

        expect { library.get_ip_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end

      it "skips an interface and ip for matching inet6 ip/128" do
        node.set["network"]["interfaces"]["eth0"]["addresses"]["21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"]["prefixlen"] = "128"
        node.set["osops_networks"]["network"] = "21DA:00D3:0000:2F3B:02AA:00FF::/32"

        expect { library.get_ip_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end

      it "returns an interface and ip for matching inet4 network" do
        node.set["osops_networks"]["network"] = "172.16.0.0/16"

        library.get_ip_for_net("network").should eq "172.16.10.1"
      end

      it "returns an interface and ip for matching inet6 network" do
        node.set["osops_networks"]["network"] =
          "21DA:00D3:0000:2F3B:02AA:00FF::/32"

        library.get_ip_for_net("network").
          should eq "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"
      end

      it "raises an exception if no matching network is found" do
        node.set["osops_networks"]["network"] = "10.10.0.0/16"

        Chef::Log.should_receive("error").with(/can't find address on network/i)

        expect { library.get_ip_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end

      it "raises an exception if no addresses on interface" do
        node.set["osops_networks"]["network"] = "10.10.0.0/16"
        node.set["network"]["interfaces"]["eth0"] = {}

        Chef::Log.should_receive("error").with(/can't find address on network/i)

        expect { library.get_ip_for_net("network") }.
          to raise_error(/can't find address on network/i)
      end
    end
  end

  describe "rcb_safe_deref" do
    let(:hash) { { "a" => { "b" => { "c" => 3 } } } }

    it "returns the value of the specific path" do
      library.rcb_safe_deref(hash, "a.b").should == { "c" => 3 }
      library.rcb_safe_deref(hash, "a.b.c").should eq 3
    end

    it "returns nil for an unknown path" do
      library.rcb_safe_deref(hash, "a.d").should be_nil
    end

    it "calls the method of the same name if available" do
      hash.stub("foop").and_return("panzers!")

      library.rcb_safe_deref(hash, "foop").should eq "panzers!"
    end
  end

  describe "#get_config_endpoint" do
    let(:service_info) do
      {
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoints/foo",
        "scheme" => "https",
        "port" => "443",
        "uri" => "http://localhost:80/endpoint"
      }
    end

    before do
      node.set["myserver"]["services"]["myservice"] = service_info

      library.stub("node").and_return(node)
    end

    it "returns nil and logs if the service is not found" do
      Chef::Log.should_receive("info").with(/no configured endpoint/i)

      library.get_config_endpoint("myserver", "unknownservice").should be_nil
    end

    it "returns hash and logs if service is not found and partial is true" do
      Chef::Log.should_receive("info").with(/no configured endpoint/i)

      library.get_config_endpoint("myserver", "unknownservice", nil, true).
        should == {}
    end

    it "returns the service info from the specified uri instead" do
      library.get_config_endpoint("myserver", "myservice").should == {
        "host" => "localhost",
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoint",
        "port" => 80,
        "scheme" => "http"
      }
    end

    it "returns the service info and creates a uri if we have host" do
      service_info["host"] = "localhost"
      service_info.delete("uri")
      node.set["myserver"]["services"]["myservice"] = service_info

      library.get_config_endpoint("myserver", "myservice").should == {
        "host" => "localhost",
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoints/foo",
        "port" => "443",
        "scheme" => "https",
        "uri" => "https://localhost:443/endpoints/foo"
      }
    end
  end

  describe "#get_bind_endpoint" do
    let(:service_info) do
      {
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoints/foo",
        "scheme" => "https",
        "port" => "443",
        "uri" => "http://localhost:80/endpoint"
      }
    end

    before do
      node.set["myserver"]["services"]["myservice"] = service_info
      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" }
      }
      node.set["osops_networks"]["management"] = "172.16.0.0/16"

      library.stub("node").and_return(node)
    end

    it "returns nil and warns if the server/service is not found" do
      Chef::Log.should_receive("warn").with(/cannot find server\/service/i)

      library.get_bind_endpoint("myserver", "unknownservice").should be_nil
    end

    it "returns the uri over any constitute parts" do
      library.get_bind_endpoint("myserver", "myservice").should == {
        "host" => "localhost",
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoint",
        "port" => 80,
        "scheme" => "http",
        "uri" => "http://localhost:80/endpoint"
      }
    end

    it "returns host from get_ip_for_net if service host is missing" do
      service_info.delete("host")
      service_info.delete("uri")
      node.set["myserver"]["services"]["myservice"] = service_info

      library.get_bind_endpoint("myserver", "myservice").should == {
        "host" => "172.16.10.1",
        "name" => "myservice",
        "network" => "management",
        "path" => "/endpoints/foo",
        "port" => "443",
        "scheme" => "https",
        "uri" => "https://172.16.10.1:443/endpoints/foo"
      }
    end
  end

  describe "#get_lb_endpoint" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [node] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = [node]
      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil if no vips are found" do
      expect { library.get_lb_endpoint("myrole", "myserver", "myservice") }.
        to raise_error(/vips.*not defined/)
    end

    context "with vips and service information" do
      let(:service_info) do
        {
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoints/foo",
          "scheme" => "https",
          "port" => "443",
          "uri" => "http://localhost:80/endpoint"
        }
      end

      before do
        node.set["myserver"]["services"]["myservice"] = service_info
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" }
        }
        node.set["osops_networks"]["management"] = "172.16.0.0/16"
      end

      it "uses the node if the name matches the search result for vips" do
        node.set["vips"]["myserver-myservice"] = "172.16.10.10"

        library.get_lb_endpoint("myrole", "myserver", "myservice").should == {
          "host" => "172.16.10.10",
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoint",
          "port" => 80,
          "scheme" => "http",
          "uri" => "http://172.16.10.10:80/endpoint"
        }
      end

      it "uses node if the name matches the search result for external vips" do
        node.set["external-vips"]["myserver-myservice"] = "172.16.10.10"

        library.get_lb_endpoint("myrole", "myserver", "myservice").should == {
          "host" => "172.16.10.10",
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoint",
          "port" => 80,
          "scheme" => "http",
          "uri" => "http://172.16.10.10:80/endpoint"
        }
      end

      it "returns nil if the realserver is empty" do
        node.set["vips"]["myserver-myservice"] = "172.16.10.10"

        library.stub("get_realserver_endpoints").and_return([{}])

        Chef::Log.should_receive("warn").with(/cannot find server\/service/i)

        library.get_lb_endpoint("myrole", "myserver", "myservice").should be_nil
      end
    end
  end

  describe "#get_mysql_endpoint" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []
      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no matching role, service, service" do
      Chef::Log.should_receive("warn").
        with(/cannot find mysql\/db for role mysql-master/i)

      library.get_mysql_endpoint.should be_nil
    end

    context "with service information" do
      let(:service_info) do
        {
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoints/foo",
          "scheme" => "https",
          "port" => "443",
          "uri" => "http://localhost:80/endpoint"
        }
      end

      before do
        node.set["mysql"]["services"]["db"] = service_info
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" }
        }
        node.set["osops_networks"]["management"] = "172.16.0.0/16"
      end

      it "uses the node if the name matches the search result" do
        results << node

        library.get_mysql_endpoint.
          should == {
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }
      end

      it "uses attributes to override the search" do
        node.set["unmanaged"]["mysql"]["host"] = "10.10.10.10"

        library.get_mysql_endpoint.
          should == {
            "host" => "10.10.10.10",
            "name" => "mysql"
          }
      end

      it "uses the node if the role contains the search result" do
        node.set["roles"] = ["mysql-master"]

        library.get_mysql_endpoint.
          should == {
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }
      end

      it "find the lb vips for more than one result" do
        node.set["vips"]["mysql-db"] = "172.16.10.10"
        node.stub("name").and_return("first")

        other_node = Chef::Node.new
        other_node.stub("name").and_return("other_node")

        results << node << other_node

        library.get_mysql_endpoint.
          should == {
            "host" => "172.16.10.10",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://172.16.10.10:80/endpoint"
          }
      end
    end
  end

  describe "#get_access_endpoint" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []
      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no matching role, service, service" do
      Chef::Log.should_receive("warn").
        with(/cannot find unknown\/unknown for role unknown/i)

      library.get_access_endpoint("unknown", "unknown", "unknown").should be_nil
    end

    context "with service information" do
      let(:service_info) do
        {
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoints/foo",
          "scheme" => "https",
          "port" => "443",
          "uri" => "http://localhost:80/endpoint"
        }
      end

      before do
        node.set["myserver"]["services"]["myservice"] = service_info
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" }
        }
        node.set["osops_networks"]["management"] = "172.16.0.0/16"
      end

      it "uses the node if the name matches the search result" do
        results << node

        library.get_access_endpoint("myrole", "myserver", "myservice").
          should == {
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }
      end

      it "uses the node if the role contains the search result" do
        node.set["roles"] = ["myrole"]

        library.get_access_endpoint("myrole", "myserver", "myservice").
          should == {
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }
      end

      it "find the lb vips for more than one result" do
        node.set["vips"]["myserver-myservice"] = "172.16.10.10"
        node.stub("name").and_return("first")

        other_node = Chef::Node.new
        other_node.stub("name").and_return("other_node")

        results << node << other_node

        library.get_access_endpoint("myrole", "myserver", "myservice").
          should == {
            "host" => "172.16.10.10",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://172.16.10.10:80/endpoint"
          }
      end
    end
  end

  describe "#get_realserver_endpoints" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []
      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns empty array for no matching role, service, service" do
      library.get_realserver_endpoints("unknown", "unknown", "unknown").
        should == []
    end

    context "with service information" do
      let(:service_info) do
        {
          "name" => "myservice",
          "network" => "management",
          "path" => "/endpoints/foo",
          "scheme" => "https",
          "port" => "443",
          "uri" => "http://localhost:80/endpoint"
        }
      end

      before do
        node.set["myserver"]["services"]["myservice"] = service_info
        node.set["network"]["interfaces"]["eth0"]["addresses"] = {
          "172.16.10.1" => { "family" => "inet" }
        }
        node.set["osops_networks"]["management"] = "172.16.0.0/16"
      end

      it "uses the node if the name matches the search result" do
        results << node

        library.get_realserver_endpoints("myrole", "myserver", "myservice").
          should == [{
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }]
      end

      it "uses the node if the role contains the search result" do
        node.set["roles"] = ["myrole"]

        library.get_realserver_endpoints("myrole", "myserver", "myservice").
          should == [{
            "host" => "localhost",
            "name" => "myservice",
            "network" => "management",
            "path" => "/endpoint",
            "port" => 80,
            "scheme" => "http",
            "uri" => "http://localhost:80/endpoint"
          }]
      end
    end
  end

  describe "#get_mysql_settings" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no search results" do
      library.get_mysql_settings.should be_nil
    end

    it "includes itself if the node has the role" do
      node.set["roles"] = ["mysql-master"]
      node.set["mysql"] = "foop"

      library.get_mysql_settings.should eq "foop"
    end

    it "uses unmanaged attributes if set" do
      node.set["unmanaged"]["mysql"]["host"] = "10.10.10.10"
      node.set["unmanaged"]["mysql"]["server_root_password"] = "overpass"

      library.get_mysql_settings.should == {
        "host" => "10.10.10.10",
        "server_root_password" => "overpass"
      }
    end

    it "remove node from results if includeme is false" do
      node.set["roles"] = ["mysql-master"]
      node.set["mysql"] = "foop"
      results << node

      library.get_mysql_settings("mysql-master", "mysql", includeme=false).should be_nil
    end

    it "gets information from node result" do
      node = Chef::Node.new
      node.set["roles"] = ["mysql-master"]
      node.set["mysql"] = "foop"
      results << node

      library.get_mysql_settings.should eq "foop"
    end
  end

  describe "#get_settings_by_role" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no search results" do
      library.get_settings_by_role("unknown", "unknown").should be_nil
    end

    it "includes itself if the node has the role" do
      node.set["roles"] = ["myrole"]
      node.set["mysetting"] = "foop"

      library.get_settings_by_role("myrole", "mysetting").should eq "foop"
    end

    it "remove node from results if includeme is false" do
      node.set["roles"] = ["myrole"]
      node.set["mysetting"] = "foop"
      results << node

      library.get_settings_by_role("myrole", "mysetting", false).should be_nil
    end

    it "gets information from node result" do
      node = Chef::Node.new
      node.set["roles"] = ["myrole"]
      node.set["mysetting"] = "foop"
      results << node

      library.get_settings_by_role("myrole", "mysetting").should eq "foop"
    end
  end

  describe "#get_role_count" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = ["myrole"]
      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns 0 for no search results" do
      library.get_role_count("unknown").should eq 0
    end

    it "excludes node from results if includeme is false" do
      results << node

      library.get_role_count("myrole", false).should eq 0
    end

    it "returns node if role matches but it's ot in the results" do
      library.get_role_count("myrole").should eq 1
    end
  end

  describe "#get_settings_by_recipe" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no search results" do
      library.get_settings_by_recipe("unknown", "unknown").should be_nil
    end

    it "returns the node settings if it includes the recipes" do
      node.set["recipes"] = ["myrecipe"]
      node.set["mysetting"]  = "foop"

      library.get_settings_by_recipe("myrecipe", "mysetting").should eq "foop"
    end

    it "returns the results settings" do
      node = Chef::Node.new
      node.set["recipes"] = ["myrecipe"]
      node.set["mysetting"]  = "foop"
      results << node

      library.get_settings_by_recipe("myrecipe", "mysetting").should eq "foop"
    end
  end

  describe "#get_nodes_by_role" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["roles"] = []

      library.stub("node").and_return(node)
    end

    it "returns [] for no search results" do
      results = library.get_nodes_by_role("unknown")
      results.should be_an_instance_of(Array)
      results.should be_empty
    end

    it "returns the nodes if it includes the role" do
      node.set["roles"] = ["myrole"]

      library.get_nodes_by_role("myrole").should eq [node]
    end
  end

  describe "#get_nodes_by_recipe" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["recipes"] = []

      library.stub("node").and_return(node)
    end

    it "returns [] for no search results" do
      results = library.get_nodes_by_recipe("unknown")
      results.should be_an_instance_of(Array)
      results.should be_empty
    end

    it "returns the nodes if it includes the recipe" do
      node.set["recipes"] = ["myrecipe"]

      library.get_nodes_by_recipe("myrecipe").should eq [node]
    end
  end

  describe "#get_settings_by_tag" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["tags"] = []

      library.stub("node").and_return(node)
    end

    it "returns nil for no search results" do
      library.get_settings_by_tag("unknown", "unknown").should be_nil
    end

    it "returns the node settings if it includes the tag" do
      node.set["tags"] = ["mytag"]
      node.set["mysetting"]  = "foop"

      library.get_settings_by_tag("mytag", "mysetting").should eq "foop"
    end

    it "returns the results settings" do
      node = Chef::Node.new
      node.set["tags"] = ["mytag"]
      node.set["mysetting"]  = "foop"
      results << node

      library.get_settings_by_tag("mytag", "mysetting").should eq "foop"
    end
  end

  describe "#get_nodes_by_tag" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["tags"] = []

      library.stub("node").and_return(node)
    end

    it "returns [] for no search results" do
      results = library.get_nodes_by_tag("unknown")
      results.should be_an_instance_of(Array)
      results.should be_empty
    end

    it "returns the nodes if it includes the tag" do
      node.set["tags"] = ["mytag"]

      library.get_nodes_by_tag("mytag").should eq [node]
    end
  end
end

describe Chef::Recipe::IPManagement do
  let(:library) { Chef::Recipe::IPManagement }
  let(:node) { Chef::Node.new }

  describe ".get_ip_for_net" do
    before do
      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" },
        "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
      }
    end

    it "returns 0.0.0.0 for all" do
      library.get_ip_for_net("all", node).should eq "0.0.0.0"
    end

    it "returns 127.0.0.1 for localhost" do
      library.get_ip_for_net("localhost", node).should eq "127.0.0.1"
    end

    it "logs and raises an error for no networks" do
      node.set["osops"] = {}

      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ip_for_net("nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "logs and raises an error for a missing network" do
      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ip_for_net("nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "returns an interface and ip for matching inet4 network" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ip_for_net("network", node).should eq "172.16.10.1"
    end

    it "returns an interface and ip for matching inet6 network" do
      node.set["osops_networks"]["network"] =
        "21DA:00D3:0000:2F3B:02AA:00FF::/32"

      library.get_ip_for_net("network", node).
        should eq "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"
    end

    it "uses osops network mappings if available" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["mapping"]["mynetwork"] = "network"

      library.get_ip_for_net("mynetwork", node).should eq "172.16.10.1"
    end

    it "raises an exception if no matching network is found" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ip_for_net("network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no addresses on interface" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"
      node.set["network"]["interfaces"]["eth0"] = {}

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ip_for_net("network", node) }.
        to raise_error(/can't find address on network/i)
    end
  end

  describe ".get_ips_for_recipe" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" },
        "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
      }

      node.set["recipes"] = ["myrecipe"]
    end

    it "returns 0.0.0.0 for all" do
      library.get_ips_for_recipe("myrecipe", "all", node).should eq ["0.0.0.0"]
    end

    it "returns 127.0.0.1 for localhost" do
      library.get_ips_for_recipe("myrecipe", "localhost", node).
        should eq ["127.0.0.1"]
    end

    it "logs and raises an error for no networks" do
      node.set["osops"] = {}

      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_recipe("myrecipe", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "logs and raises an error for a missing network" do
      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_recipe("myrecipe", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "returns an interface and ip for matching inet4 network" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_recipe("myrecipe", "network", node).
        should eq ["172.16.10.1"]
    end

    it "returns an interface and ip for matching inet6 network" do
      node.set["osops_networks"]["network"] =
        "21DA:00D3:0000:2F3B:02AA:00FF::/32"

      library.get_ips_for_recipe("myrecipe", "network", node).
        should eq ["21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"]
    end

    it "uses osops network mappings if available" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["mapping"]["mynetwork"] = "network"

      library.get_ips_for_recipe("myrecipe", "mynetwork", node).
        should eq ["172.16.10.1"]
    end

    it "raises an exception if no matching network is found" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_recipe("myrecipe", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no addresses on interface" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"
      node.set["network"]["interfaces"]["eth0"] = {}

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_recipe("myrecipe", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no recipes match" do
      expect { library.get_ips_for_recipe("unknown", "network", node) }.
        to raise_error(/can't find any candidates for search in recipe/i)
    end

    it "ignores recipes under chef solo" do
      Chef::Config.stub("[]").and_return(true)

      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_recipe("unknown", "all", node).should eq ["0.0.0.0"]
    end
  end

  describe ".get_ips_for_role" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" },
        "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
      }

      node.set["roles"] = ["myrole"]
    end

    it "returns 0.0.0.0 for all" do
      library.get_ips_for_role("myrole", "all", node).should eq ["0.0.0.0"]
    end

    it "returns 127.0.0.1 for localhost" do
      library.get_ips_for_role("myrole", "localhost", node).
        should eq ["127.0.0.1"]
    end

    it "logs and raises an error for no networks" do
      node.set["osops"] = {}

      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_role("myrole", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "logs and raises an error for a missing network" do
      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_role("myrole", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "returns an interface and ip for matching inet4 network" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_role("myrole", "network", node).
        should eq ["172.16.10.1"]
    end

    it "returns an interface and ip for matching inet6 network" do
      node.set["osops_networks"]["network"] =
        "21DA:00D3:0000:2F3B:02AA:00FF::/32"

      library.get_ips_for_role("myrole", "network", node).
        should eq ["21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"]
    end

    it "uses osops network mappings if available" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["mapping"]["mynetwork"] = "network"

      library.get_ips_for_role("myrole", "mynetwork", node).
        should eq ["172.16.10.1"]
    end

    it "raises an exception if no matching network is found" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_role("myrole", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no addresses on interface" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"
      node.set["network"]["interfaces"]["eth0"] = {}

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_role("myrole", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no roles match" do
      expect { library.get_ips_for_role("unknown", "network", node) }.
        to raise_error(/can't find any candidates for search in role/i)
    end

    it "ignores roles under chef solo" do
      Chef::Config.stub("[]").and_return(true)

      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_role("unknown", "all", node).should eq ["0.0.0.0"]
    end
  end

  describe ".get_ips_for_tag" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" },
        "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
      }

      node.set["tags"] = ["mytag"]
    end

    it "returns 0.0.0.0 for all" do
      library.get_ips_for_tag("mytag", "all", node).should eq ["0.0.0.0"]
    end

    it "returns 127.0.0.1 for localhost" do
      library.get_ips_for_tag("mytag", "localhost", node).
        should eq ["127.0.0.1"]
    end

    it "logs and raises an error for no networks" do
      node.set["osops"] = {}

      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_tag("mytag", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "logs and raises an error for a missing network" do
      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_ips_for_tag("mytag", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "returns an interface and ip for matching inet4 network" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_tag("mytag", "network", node).
        should eq ["172.16.10.1"]
    end

    it "returns an interface and ip for matching inet6 network" do
      node.set["osops_networks"]["network"] =
        "21DA:00D3:0000:2F3B:02AA:00FF::/32"

      library.get_ips_for_tag("mytag", "network", node).
        should eq ["21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"]
    end

    it "uses osops network mappings if available" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["mapping"]["mynetwork"] = "network"

      library.get_ips_for_tag("mytag", "mynetwork", node).
        should eq ["172.16.10.1"]
    end

    it "raises an exception if no matching network is found" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_tag("mytag", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no addresses on interface" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"
      node.set["network"]["interfaces"]["eth0"] = {}

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_ips_for_tag("mytag", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no tags match" do
      expect { library.get_ips_for_tag("unknown", "network", node) }.
        to raise_error(/can't find any candidates for search in tag/i)
    end

    it "ignores tags under chef solo" do
      Chef::Config.stub("[]").and_return(true)

      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_ips_for_tag("unknown", "all", node).should eq ["0.0.0.0"]
    end
  end

  describe ".get_access_ip_for_role" do
    let(:query) { double(Chef::Search::Query) }
    let(:results) { [] }

    before do
      Chef::Search::Query.stub("new").and_return(query)
      query.stub("search").and_return([results, nil, nil])

      node.set["network"]["interfaces"]["eth0"]["addresses"] = {
        "172.16.10.1" => { "family" => "inet" },
        "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A" => { "family" => "inet6" }
      }

      node.set["roles"] = ["myrole"]
    end

    it "returns 0.0.0.0 for all" do
      library.get_access_ip_for_role("myrole", "all", node).
        should eq "0.0.0.0"
    end

    it "returns 127.0.0.1 for localhost" do
      library.get_access_ip_for_role("myrole", "localhost", node).
        should eq "127.0.0.1"
    end

    it "logs and raises an error for no networks" do
      node.set["osops"] = {}

      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_access_ip_for_role("myrole", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "logs and raises an error for a missing network" do
      Chef::Log.should_receive("error").with(/network 'nonet' is not defined/i)

      expect { library.get_access_ip_for_role("myrole", "nonet", node) }.
        to raise_error(/network 'nonet' is not defined/i)
    end

    it "returns an interface and ip for matching inet4 network" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_access_ip_for_role("myrole", "network", node).
        should eq "172.16.10.1"
    end

    it "returns an interface and ip for matching inet6 network" do
      node.set["osops_networks"]["network"] =
        "21DA:00D3:0000:2F3B:02AA:00FF::/32"

      library.get_access_ip_for_role("myrole", "network", node).
        should eq "21DA:00D3:0000:2F3B:02AA:00FF:FE28:9C5A"
    end

    it "uses osops network mappings if available" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["mapping"]["mynetwork"] = "network"

      library.get_access_ip_for_role("myrole", "mynetwork", node).
        should eq "172.16.10.1"
    end

    it "raises an exception if no matching network is found" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_access_ip_for_role("myrole", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no addresses on interface" do
      node.set["osops_networks"]["network"] = "10.10.0.0/16"
      node.set["network"]["interfaces"]["eth0"] = {}

      Chef::Log.should_receive("error").with(/can't find address on network/i)

      expect { library.get_access_ip_for_role("myrole", "network", node) }.
        to raise_error(/can't find address on network/i)
    end

    it "raises an exception if no roles match" do
      Chef::Log.should_receive("error").
        with(/can't find any candidates for role/i)

      expect { library.get_access_ip_for_role("unknown", "network", node) }.
        to raise_error(/can't find any candidates for role/i)
    end

    it "ignores roles under chef solo" do
      Chef::Config.stub("[]").and_return(true)

      node.set["osops_networks"]["network"] = "172.16.0.0/16"

      library.get_access_ip_for_role("unknown", "all", node).should eq "0.0.0.0"
    end

    it "returns an vips ip from osops networks roles if multiple results" do
      node.set["osops_networks"]["network"] = "172.16.0.0/16"
      node.set["osops_networks"]["vips"]["myrole"] = "172.16.10.10"

      # return multiple results
      library.stub("osops_search").and_return([node, node])

      library.get_access_ip_for_role("myrole", "network", node).
        should eq "172.16.10.10"
    end

    it "raises exception on multiple results with no vips role in osops" do
      # return multiple results
      library.stub("osops_search").and_return([node, node])

      Chef::Log.should_receive("error").with(/can't find lb vip for role 'unknown'/i)

      expect { library.get_access_ip_for_role("unknown", "network", node) }.
        to raise_error(/can't find lb vip for role 'unknown'/i)
    end
  end
end
