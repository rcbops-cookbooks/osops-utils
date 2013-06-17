require "spec_helper"
require "chef/node"
require "libraries/patch"

describe Chef::Recipe::Patch do
  let(:library) { Chef::Recipe::Patch }
  let(:package) { "mypackage" }
  let(:version) { "1.0" }

  describe ".chef_package_version" do
    context "with missing attributes" do
      let(:node) { Chef::Node.new }

      before do
        library.stub("node").and_return(node)
      end

      it "returns false if no osops attr exists" do
        node.set["osops"]["apply_patches"] = false

        library.check_package_version(package, version).should be_false
      end

      it "returns false if no nova attr exists" do
        node.set["osops"]["apply_patches"] = false

        library.check_package_version(package, version).should be_false
      end
    end

    context "with a Chef node" do
      let(:node) { Chef::Node.new }

      before do
        node.set["osops"]["apply_patches"] = true
        node.set["nova"]["apply_patches"] = true
        node.set["platform"] = "debian"

        library.stub("node").and_return(node)
      end

      it "returns false if no ['apply_patches'] are true" do
        node.set["osops"]["apply_patches"] = false
        node.set["nova"]["apply_patches"] = false

        Chef::Log.should_receive("info").with(/skipping.*due to node settings/)

        library.check_package_version(package, version).should be_false
      end

      it "returns false for an unknown platform" do
        node.set["platform"] = "unknown"

        library.check_package_version(package, version).should be_false
      end

      ["debian", "ubuntu"].each do |platform|
        context "on #{platform}" do
          before { node.set["platform"] = platform }

          it "returns true if the package version is installed" do
            Mixlib::ShellOut.
              stub_chain(:new, :run_command, :stdout, :each_line).
              and_yield("  Installed: #{version}")

            Chef::Log.should_receive("info").with(/requires a hotfix/)

            library.check_package_version(package, version).should be_true
          end

          it "returns false if the package version is not installed" do
            Mixlib::ShellOut.
              stub_chain(:new, :run_command, :stdout, :each_line).
              and_yield("  Installed: 2.0")

            library.check_package_version(package, version).should be_false
          end
        end
      end

      ["fedora", "centos", "redhat", "scientific", "amazon"].each do |platform|
        context "on #{platform}" do
          before { node.set["platform"] = platform }

          it "returns true of the package version is installed" do
            Mixlib::ShellOut.
              stub_chain(:new, :run_command, :stdout, :each_line).
              and_yield(version)

            Chef::Log.should_receive("info").with(/requires a hotfix/)

            library.check_package_version(package, version).should be_true
          end

          it "returns false of the package version is not installed" do
            Mixlib::ShellOut.
              stub_chain(:new, :run_command, :stdout, :each_line).
              and_yield("2.0")

            library.check_package_version(package, version).should be_false
          end
        end
      end
    end
  end
end
