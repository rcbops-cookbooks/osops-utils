require "spec_helper"
require "libraries/database"

describe RCB do
  let(:library) { Object.new.extend(RCB) }
  let(:mysql_info) { { "server_root_password" => "serverpassword" } }
  let(:connection_info) do
    {
      :host => endpoint["host"],
      :username => "root",
      :password => mysql_info["server_root_password"]
    }
  end
  let(:endpoint) { { "host" => "127.0.0.1" } }
  let(:database) { "mydb" }
  let(:username) { "myuser" }
  let(:password) { "mypass" }

  describe "#create_db_and_user" do
    before do
      library.stub("get_access_endpoint").and_return(endpoint)
      library.stub("get_settings_by_role").and_return(mysql_info)
    end

    it "returns nil for all unknown db types" do
      library.create_db_and_user("notmysql", database, username, password).
        should be_nil
    end

    it "creates the db and user" do
      library.should_receive("mysql_database").with("create mydb database").
        and_yield do |object|

          object.should_receive("connection").with(connection_info)
          object.should_receive("database_name").with(database)
          object.should_receive("action").with(:create)
      end

      library.should_receive("mysql_database_user").with(username).
        and_yield do |object|

          object.should_receive("connection").with(connection_info)
          object.should_receive("password").with(password)
          object.should_receive("action").with(:create)
      end

      library.should_receive("mysql_database_user").with(username).
        and_yield do |object|

          object.should_receive("connection").with(connection_info)
          object.should_receive("password").with(password)
          object.should_receive("database_name").with(database)
          object.should_receive("host").with("%")
          object.should_receive("privileges").with([:all])
          object.should_receive("action").with(:grant)
      end

      library.create_db_and_user("mysql", database, username, password).
        should eq mysql_info
    end
  end
end
