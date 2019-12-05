#
# Copyright:: 2019, Chef Software Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module RuboCop
  module Cop
    module Chef
      module ChefDeprecations
        # Use delete_resource / edit_resource instead of functionality in the deprecated chef-rewind gem
        #
        # @example
        #
        #   chef_gem 'chef-rewind'
        #
        #   require 'chef/rewind'
        #
        #   rewind "user[postgres]" do
        #     home '/var/lib/pgsql/9.2'
        #     cookbook 'my-postgresql'    # or `cookbook cookbook_name()`
        #   end
        #
        #   unwind "user[postgres]"
        #
        class ChefRewind < Cop
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Use delete_resource / edit_resource instead of functionality in the deprecated chef-rewind gem'.freeze

          def_node_matcher :rewind_gem_install?, <<-PATTERN
            (send nil? :chef_gem (str "chef-rewind"))
          PATTERN

          def_node_matcher :require_rewind?, <<-PATTERN
            (send nil? :require (str "chef/rewind"))
          PATTERN

          def on_send(node)
            rewind_gem_install?(node) do
              add_offense(node, location: :expression, message: MSG, severity: :refactor)
            end

            require_rewind?(node) do
              add_offense(node, location: :expression, message: MSG, severity: :refactor)
            end

            add_offense(node, location: :expression, message: MSG, severity: :refactor) if %i(rewind unwind).include?(node.method_name)
          end

          def on_block(node)
            match_property_in_resource?(:chef_gem, 'package_name', node) do |pkg_name|
              add_offense(node, location: :expression, message: MSG, severity: :refactor) if pkg_name.arguments&.first&.str_content == 'chef-rewind'
            end
          end

          def autocorrect(node)
            lambda do |corrector|
              rewind_gem_install?(node) do
                node = node.parent if node.parent&.block_type? # make sure we get the whole block not just the method in the block
                corrector.remove(node.loc.expression)
              end

              require_rewind?(node) do
                corrector.remove(node.loc.expression)
              end

              match_property_in_resource?(:chef_gem, 'package_name', node) do |pkg_name|
                corrector.remove(node.loc.expression) if pkg_name.arguments&.first&.str_content == 'chef-rewind'
              end
            end
          end
        end
      end
    end
  end
end
