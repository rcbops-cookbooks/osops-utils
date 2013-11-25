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
  def create_db_and_user(db_vendor, db_name, username, pw, options = {})
    options = { :role => "mysql-master" }.merge(options)
    role = options[:role]

    if db_vendor == "mysql"
      connect_host = get_mysql_endpoint(role)["host"]
      mysql_info = get_mysql_settings(role)

      connection_info = { :host => connect_host,
        :username => "root",
        :password => mysql_info["server_root_password"] }

      # create database
      mysql_database "create #{db_name} database" do
        connection connection_info
        database_name db_name
        action :create
      end

      # create/user & grant privs to user
      mysql_database_user username do
        connection connection_info
        password pw
        database_name db_name
        host '%'
        privileges [:all]
        action [:create, :grant]
      end

      return mysql_info
    end

    return
  end

  def add_index_stopgap(db_vendor, db_name, username, pw, idn, tbl, col, res, cmd, options = {})
    options = { :role => "mysql-master" }.merge(options)

    if db_vendor == "mysql"
      log "Index Check/Creation for #{idn} on table #{tbl} for column #{col}"
      connect_host = get_access_endpoint(options[:role], "mysql", "db")["host"]
      ruby_block "index and check #{idn}" do
        block do
          require 'mysql'
          con = Mysql.new(connect_host, username, pw, db_name)
          tbl_exist = con.query("show tables like \"#{tbl}\"")
          Chef::Log.debug("number of table rows #{tbl_exist.num_rows()}")
          if tbl_exist.nil? or tbl_exist.num_rows() > 0
            col_exist = con.query("show columns from `#{tbl}` like \"#{col}\"")
            Chef::Log.debug("number of column rows #{col_exist.num_rows()}")
            if col_exist.nil? or col_exist.num_rows() > 0
              idn_exist = con.query("show index from `#{tbl}` where key_name = \"#{idn}\"")
              Chef::Log.debug("number of index rows #{idn_exist.num_rows()}")
              if idn_exist.nil? or idn_exist.num_rows() == 0
                Chef::Log.info("Creating index #{idn} on #{tbl} (#{col})")
                con.query("create index #{idn} on #{tbl} (#{col})")
              end
            end
          end
          con.close
        end
        subscribes cmd, res, :delayed
      end
    end
  end

end
