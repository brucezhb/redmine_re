require 'redmine'

Redmine::Plugin.register :redmine_re do
	name 'Redmine Requirements Engineering Plugin'
	author 'Bonn-Rhine-Sieg University of Applied Sciences (thorsten.merten@h-brs.de)'
	description 'This is a plugin to handle requirements engineering artifacts within redmine. The plugin has been developed
within the KoREM project (http://korem.de) at Bonn-Rhine-Sieg University of Applied Sciences (http://h-brs.de)'
	version '0.0.1'
	url 'http://korem.de/redmineplugin'
	author_url 'http://korem.de'

	# this plugin creates a project module. navigate to 'settings->modules' in the app to activate the plugin per project
	project_module :requirements do

    #   before_filter :authorize is set in the redmine_re_controller
		permission( :edit_requirements,
      {
        # actions of redmine_re_controller are here too because the get executed by inheritance of requirements controller
        # for example here:_tree partial: <%= url_for :controller => 'requirements', :action => 'context_menu' %>
        :requirements => [:index, :treeview, :context_menu, :treestate, :load_settings, :find_project, :add_hidden_re_artifact_properties_attributes, :create_tree, :delegate_tree_drop, :render_to_html_tree, :render_children_to_html_tree, :enhanced_filter, :build_conditions_hash, :find_first_artifacts_with_first_parameter, :reduce_search_result_with_parameter],#todo:
        :re_artifact_properties => [:edit, :redirect, :delete],
        :re_goal => [:edit, :new] ,
        :re_task => [:edit, :new, :delete_subtask],
        :re_subtask => [:edit, :new],
        :re_section => [:edit, :new],
        :re_workarea => [:edit, :new],
        :re_vision => [:edit, :new],
        :re_user_profile => [:edit, :new],
        :re_attachment => [:edit, :new, :download_or_show],
        :re_artifact_relationship => [:prepare_relationships, :visualization, :build_json_for_netmap, :add_artifacts_as_children_of_root, :add_artifact, :remove_last_comma_and_close, :build_json_according_to_user_choice]
      }
    )

	# more restrictive setup manage_requirements becomes "Manage Requirements" by convention
	# permission :manage_requirements, :requirements => :index
	end

	# The Requirements item is added to the project menu after the Activity item
	menu :project_menu, :re, { :controller => 'requirements', :action => 'index' }, :caption => 'Requirements', :after => :activity, :param => :project_id
	#menu :project_menu, :re, { :controller => 'requirements', :action => 'index' }, :caption => 'Requirements', :after => :activity, :param => :project_id

	# ReArtifactProperties can be added to the activity view
	#activity_provider :re_artifact_properties

	#Observers
	config.active_record.observers = :re_artifact_properties_observer

	#ActiveSupport::Dependencies.load_once_paths.delete(File.expand_path(File.dirname(__FILE__))+'/lib')

	# add "acts_as_re_artifact" method to any ActiveRecord::Base class
	# as an alias to "include Artifact"
	settings :default => {
    're_artifact_types' => ''
  }, :partial => 'settings/re_settings'

	class ActiveRecord::Base
		def self.acts_as_re_artifact
			include Artifact
		end
	end

end

config.after_initialize do
	settings = Setting["plugin_redmine_re"]

	configured_artifact_types = Array.new
	configured_artifact_types.concat(ActiveSupport::JSON.decode(settings['re_artifact_types'])) unless settings['re_artifact_types'].empty?

	all_artifact_types = Dir["#{RAILS_ROOT}/vendor/plugins/redmine_re/app/models/re_*.rb"].map do |f|
		fd = File.open(f, 'r')
		File.basename(f, '.rb').camelize if fd.read.include? "acts_as_re_artifact"
	end

	all_artifact_types.delete_if { |x| x.nil? }
	all_artifact_types.delete(:ReArtifactProperties)
	all_artifact_types.delete_if{ |v| configured_artifact_types.include? v }
	configured_artifact_types.concat(all_artifact_types)
	Setting["plugin_redmine_re"] = {'re_artifact_types' => ActiveSupport::JSON.encode(configured_artifact_types) }
end