class ReTaskController < RedmineReController
  unloadable

  def index
    @tasks = ReTask.find(:all,
                         :joins => :re_artifact,
                         :conditions => { :re_artifacts => { :project_id => params[:project_id]} }
    )
    render :layout => false
  end


  def new
    edit
  end

  # edit can be used for new/edit and update
  def edit
    # ToDo: Abklaeren, warum man die ID-Anpassung auch bei Post machen muss:
    # Vom Logischen her sollte es eigentlich so sein, dass dies nur bei get
    # noetig ist, da die neue ID eigentlich an das Formular und somit an das
    # post weitergeleitet werden sollte.
    #if request.get?
        # Parameter id contains id of ReArtifact, not of ReSubtask as it should be
        # This has to be changed here as it is not possible to build
        # a dynamic Ajax-Updater with data from clicked tree-element
        re_artifact_id = params[:id]
        @re_artifact = ReArtifact.find_by_id(re_artifact_id)
        params[:id] = @re_artifact.artifact_id
    #end
    @re_task = ReTask.find_by_id(params[:id], :include => :re_artifact) || ReTask.new
    @re_task.build_re_artifact unless @re_task.re_artifact
    # If no parent_id is transmitted, we don't create a new artifact but edit one
    # Therefore, a valid parent_artifact_id is existent and has to be read out
    if request.get?
        if params[:parent_id] == nil
          params[:parent_id] = @re_task.re_artifact.parent_artifact_id
        end
      end

    if request.post?
      # Params Hash anpassen

      ## 1. Den Key re_artifact in re_artifact_attributes kopieren und l�schen
      ### Params Hash aktuell BSP: "re_task"=>{"re_artifact"=>{"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}
      params[:re_task][:re_artifact_attributes] = params[:re_task].delete(:re_artifact)

      ### Params Hash aktuell BSP:"re_task"=>{"re_artifact_attributes"=>{"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}

      ## 2. Den Key re_artifact_attributes die id hinzuf�gen, weil sonst bei Edit neues ReArtifact erzeugt wird da keine Id gefunden wird
      params[:re_task][:re_artifact_attributes][:id] = @re_task.re_artifact.id

      ### Params Hash aktuell BSP:"re_task"=>{"re_artifact_attributes"=>{ "id"=>37,"name"=>"TaskArtifactEditTesterV3", "priority"=>"777777"}

      # dies funktioniert nun (nur mit re_artifact_attributes key halt)
      @re_task.attributes = params[:re_task]
      add_hidden_re_artifact_attributes @re_task.re_artifact
      @re_task.re_artifact.parent_artifact_id = params[:parent_id] if params[:parent_id] and @re_task.new_record?
      
      # Todo: Abkl�ren, wo ReArtifact gespeichert wird. Geht das �ber re_task.save automatisch?
      flash[:notice] = 'Task successfully saved' unless save_ok = @re_task.save
      # we won't put errors in the flash, since they can be displayed in the errors object

      redirect_to :action => 'index', :project_id => @project.id and return if save_ok
    end
    render :layout => false
  end

    ##
  # deletes and updates the flash with either success, id not found error or deletion error
  def delete
    @re_task = ReTask.find_by_id(params[:id], :include => :re_artifact)
    if !@re_task
      flash[:error] = 'Could not find a task with this ' + params[:id] + ' to delete'
    else
      name = @re_task.re_artifact.name
      if ReTask.delete(@re_task.id)
        flash[:notice] = 'The Task "' + name + '" has been deleted'
      else
        flash[:error] = 'The Task "' + name + '" could not be deleted'
      end
    end
    redirect_to :action => 'index', :project_id => @project.id
  end

  ##
  # unused right now
  def show
    fghfgh
    @re_task = ReTask.find_by_id(params[:id])
  end

  ##
  # shows all versions
  def show_versions
    @task = ReTask.find(params[:id] ) # :include => :re_artifact)
  end

  ##
  # reverts to an older version
  def change_version
    targetVersion = params[:version]
    @task = ReTask.find(params[:id])

    if(@task.revert_to!(targetVersion))
      flash[:notice] = 'Task version changed sucessfully'
    end

    redirect_to :action => 'index', :project_id => @project.id
  end

end
