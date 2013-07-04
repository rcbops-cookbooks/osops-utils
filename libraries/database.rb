#
# Cookbook Name:: osops-utils
# Library:: database
#
# Copyright 2009, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.dirname(__FILE__) + "/ip_location"

module RCB
  def create_db_and_user(db_vendor, db_name, username, pw)
    case db_vendor
    when "mysql"
      connect_host = get_access_endpoint("mysql-master", "mysql", "db")["host"]
      mysql_info = get_settings_by_role('mysql-master', 'mysql')
      connection_info = { :host => connect_host,
        :username => "root",
        :password => mysql_info["server_root_password"] }

      # create database
      mysql_database "create #{db_name} database" do
        connection connection_info
        database_name db_name
        action :create
      end

      # create user
      mysql_database_user username do
        connection connection_info
        password pw
        action :create
      end

      # grant privs to user
      mysql_database_user username do
        connection connection_info
        password pw
        database_name db_name
        host '%'
        privileges [:all]
        action :grant
      end

      return mysql_info
    end

    return
  end

  def add_index_stopgap(db_vendor, db_name, username, pw, idn, tbl, col)
    case db_vendor
      when "mysql"
        connect_host = get_access_endpoint("mysql-master", "mysql", "db")["host"]
        mysql_info = get_settings_by_role('mysql-master', 'mysql')
        connection_info = { :host => connect_host,
                            :username => "root",
                            :password => mysql_info["server_root_password"] }
        # create database
        mysql_database "index #{idn} add" do
          connection connection_info
          database_name db_name
          sql "create index #{idn} on #{tbl} (#{col})"
          action :query
          not_if <<-EOH
            mysql -s -N -uroot \
            -p#{mysql_info["server_root_password"]} \
            -h #{connect_host} \
            -e "show index from #{tbl} where key_name = '#{idn}'" \
            #{db_name} | grep -o #{idn}
            EOH
        end
    end
  end
end

