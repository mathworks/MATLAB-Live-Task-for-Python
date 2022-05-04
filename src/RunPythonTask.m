classdef RunPythonTask < matlab.task.LiveTask
% The MATLAB® Live Task for Python® enables you to write and execute Python code directly inside 
% of a MATLAB Live Script. Since R2022a, MATLAB provides a way to develop your own custom live task.

% Copyright 2022 The MathWorks, Inc.

    properties (Access = private, Transient, Hidden)
        SelectCodeGrid                  matlab.ui.container.GridLayout
        SelectCodeButtonGroup           matlab.ui.container.ButtonGroup
        PyrunButton                     matlab.ui.control.RadioButton
        PyrunfileButton                 matlab.ui.control.RadioButton
        PythonCodeInputGrid             matlab.ui.container.GridLayout
        InputCodeLabel                  matlab.ui.control.Label
        InputSelectFile                 matlab.ui.control.Button
        InputCode                       matlab.ui.control.TextArea
        InputCodeFileLabel              matlab.ui.control.Label
        InputVariablesGrid              matlab.ui.container.GridLayout
        NumberInputVariables            double
        InputVariableLabel(1,:)         matlab.ui.control.Label
        InputVariableValue(1,:)         matlab.ui.control.DropDown
        InputVariableWorkspace(1,:)     matlab.ui.control.DropDown
        InputVariableLiteralEdit(1,:)   matlab.ui.control.EditField
        InputVariableArrow(1,:)         matlab.ui.control.Image
        PythonVariableNameLabel(1,:)    matlab.ui.control.Label
        InputVariableNameEdit(1,:)      matlab.ui.control.EditField
        InputVariableAddButton(1,:)     matlab.ui.control.Image
        InputVariableRemoveButton(1,:)  matlab.ui.control.Image
        InputVariableUpButton(1,:)      matlab.ui.control.Image
        InputVariableDownButton(1,:)    matlab.ui.control.Image
        OutputVariablesGrid             matlab.ui.container.GridLayout
        NumberOutputVariables           double
        OutputVariableLabel(1,:)        matlab.ui.control.Label
        OutputVariableNameEdit(1,:)     matlab.ui.control.EditField
        OutputVariableAddButton         matlab.ui.control.Image
        OutputVariableRemoveButton      matlab.ui.control.Image
        OutputVariableUpButton          matlab.ui.control.Image
        OutputVariableDownButton        matlab.ui.control.Image
    end
    properties
        State
        Summary
    end   
    methods (Access = private, Hidden)
        function createComponents(task)
            task.LayoutManager.RowHeight = ["fit","fit","fit","fit","fit","fit"];
            task.LayoutManager.ColumnWidth = "fit";

            % Select code to run
            uilabel(task.LayoutManager,"Text","Select code to run","FontWeight","bold");
            task.SelectCodeGrid = uigridlayout(task.LayoutManager,"RowHeight",{30,'fit'},...
                "ColumnWidth",{'fit'},"Padding",[10 0 10 0],"RowSpacing",0);

            task.SelectCodeButtonGroup = uibuttongroup(task.SelectCodeGrid,"SelectionChangedFcn",@task.selectCode,"BorderType","none");
            task.PyrunButton = uiradiobutton(task.SelectCodeButtonGroup,"Text","Python statements","Position",[10 15 140 15]);
            task.PyrunfileButton = uiradiobutton(task.SelectCodeButtonGroup,"Text","Python script file","Position",[160 15 140 15]);

            task.PythonCodeInputGrid = uigridlayout(task.SelectCodeGrid,"RowHeight",{'fit',80},...
                "ColumnWidth",{95,500});
            task.PythonCodeInputGrid.Padding(2) = 0;
            task.PythonCodeInputGrid.Padding(4) = 0;
            task.InputCodeLabel = uilabel(task.PythonCodeInputGrid,"Text","Python Code");

            task.InputSelectFile = uibutton(task.PythonCodeInputGrid,"Text","Select File",...
                "Icon",fullfile("images","folder.png"),"IconAlignment","right","Visible","off","ButtonPushedFcn",@task.selectFile);
            task.InputSelectFile.Layout.Row = 1;
            task.InputSelectFile.Layout.Column = 1;

            task.InputCode = uitextarea("Parent",task.PythonCodeInputGrid,"ValueChangedFcn", @task.updateControls);
            task.InputCode.Layout.Row = [1,2];
            task.InputCode.Layout.Column = 2;

            task.InputCodeFileLabel = uilabel(task.PythonCodeInputGrid,"Text","No file selected","FontAngle","italic","Visible","off");
            task.InputCodeFileLabel.Layout.Row = 1;
            task.InputCodeFileLabel.Layout.Column = 2;

            % Specify input variables
            uilabel(task.LayoutManager,"Text","Specify input variables","FontWeight","bold"); 
            task.InputVariablesGrid = uigridlayout(task.LayoutManager,"RowHeight",{22},...
                 "ColumnWidth",{'fit','fit','fit',16,'fit','fit',16,16,16,16},"Padding",[20 0 10 0]);

            task.NumberInputVariables = 0;
            task.InputVariableLabel = uilabel(task.InputVariablesGrid,"Text","Input variable");
            task.InputVariableValue(task.NumberInputVariables + 1) = ...
                uidropdown("Parent", task.InputVariablesGrid,"Enable","off", ...
                "Items",{'MATLAB variable','Literal value'},"ValueChangedFcn",@task.updateRowVariableSelection);
            task.InputVariableWorkspace(task.NumberInputVariables + 1) = ...
                uidropdown("Parent",task.InputVariablesGrid,"Enable","off", ...
                "Items",{'select from workspace'},"DropDownOpeningFcn",@task.populateWorkspace,...
                "ValueChangedFcn",@task.prefillPythonVariableName);
            task.InputVariableLiteralEdit(task.NumberInputVariables + 1) = ...
                uieditfield(task.InputVariablesGrid,"Visible","off","ValueChangedFcn",@task.updateControls);
            task.InputVariableLiteralEdit.Layout.Column = task.InputVariableLiteralEdit.Layout.Column-1;
            task.InputVariableArrow(task.NumberInputVariables + 1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","arrow-right.png"));
            task.PythonVariableNameLabel = uilabel(task.InputVariablesGrid,"Text","Python variable name");
            task.InputVariableNameEdit(task.NumberInputVariables + 1) = ...
                uieditfield(task.InputVariablesGrid,"Enable","off",...
                "ValueChangedFcn",@task.updateControls);
            task.InputVariableRemoveButton(task.NumberInputVariables + 1) = uiimage(task.InputVariablesGrid, ...
                "ImageSource",fullfile("images","minus.png"),"Enable","off","ImageClickedFcn",{@task.removeVariableRowUpdate,"Input"});
            task.InputVariableAddButton(task.NumberInputVariables + 1) = uiimage(task.InputVariablesGrid, ...
                "ImageSource",fullfile("images","plus.png"),"ImageClickedFcn",{@task.addVariableRowUpdate,"Input"});
            task.InputVariableUpButton(task.NumberInputVariables + 1) = uiimage(task.InputVariablesGrid, ...
                "ImageSource",fullfile("images","up.png"),"ImageClickedFcn",{@task.moveVariableRowUpdate,"Input"},"Enable","off");
            task.InputVariableDownButton(task.NumberInputVariables + 1) = uiimage(task.InputVariablesGrid,...
                "ImageSource",fullfile("images","down.png"),"ImageClickedFcn",{@task.moveVariableRowUpdate,"Input"},"Enable","off");

            % Specify output variables
            uilabel(task.LayoutManager,"Text","Specify output variables","FontWeight","bold");
            task.OutputVariablesGrid = uigridlayout(task.LayoutManager,"RowHeight",{22},...
                "ColumnWidth",{'fit','fit',16,16,16,16},"Padding",[20 0 10 0]);
            task.NumberOutputVariables = 0;
            task.OutputVariableLabel(task.NumberOutputVariables + 1) = ...
                uilabel(task.OutputVariablesGrid,"Text","Python variable name");
            task.OutputVariableNameEdit(task.NumberOutputVariables + 1) = ...
                uieditfield(task.OutputVariablesGrid,"Enable","off","ValueChangedFcn",@task.updateControls);
            task.OutputVariableRemoveButton = uiimage(task.OutputVariablesGrid, ...
                "ImageSource",fullfile("images","minus.png"),"Enable","off","ImageClickedFcn",{@task.removeVariableRowUpdate, "Output"});
            task.OutputVariableAddButton = uiimage(task.OutputVariablesGrid, ...
                "ImageSource",fullfile("images","plus.png"),"ImageClickedFcn",{@task.addVariableRowUpdate,"Output"});
            task.OutputVariableUpButton = uiimage(task.OutputVariablesGrid, ...
                "ImageSource",fullfile("images","up.png"),"Enable","off","ImageClickedFcn",{@task.moveVariableRowUpdate, "Output"});
            task.OutputVariableDownButton = uiimage(task.OutputVariablesGrid, ...
                "ImageSource",fullfile("images","down.png"),"Enable","off","ImageClickedFcn",{@task.moveVariableRowUpdate,"Output"});
        end
        function updateControls(task,~,~)
            % Trigger the live editor to update the generated script
            notify(task,'StateChanged');
        end
        function selectCode(task,src,~)
            if src.SelectedObject.Text == "Python script file"
                task.InputCodeLabel.Visible = "off";
                task.InputCode.Visible = "off";
                task.InputSelectFile.Visible = "on";
                task.InputCodeFileLabel.Visible = "on";
                task.PythonCodeInputGrid.ColumnWidth = {95,'fit'};
                task.PythonCodeInputGrid.RowHeight = {22};
                task.InputCode.Layout.Row = 1;
            else % src.SelectedObject == "Python statements"
                task.InputSelectFile.Visible = "off";
                task.InputCodeFileLabel.Visible = "off";
                task.InputCodeLabel.Visible = "on";
                task.InputCode.Visible = "on";
                task.PythonCodeInputGrid.RowHeight = {'fit',80};
                task.PythonCodeInputGrid.ColumnWidth = {95,500};
                task.InputCode.Layout.Row = [1,2];
                task.InputSelectFile.UserData = [];
                task.InputCodeFileLabel.Text = "No file selected";
            end
            task.InputCode.Value = "";
        end
        function selectFile(task,~,~)
            [file,path] = uigetfile(".py");
            if file ~= 0
                task.InputSelectFile.UserData = fullfile(path,file);
                task.InputCodeFileLabel.Text = task.InputSelectFile.UserData;
                updateControls(task);
            end
        end
        function updateRowVariableSelection(task,src,~)
            rowLocation = src.Layout.Row;
            if src.Value == "Literal value"
                task.InputVariableWorkspace(rowLocation).Visible = "off";
                task.InputVariableLiteralEdit(rowLocation).Visible = "on";
                task.InputVariableLiteralEdit(rowLocation).Value = "";
            else % src.Value == "MATLAB variable"
                task.InputVariableLiteralEdit(rowLocation).Visible = "off";
                task.InputVariableWorkspace(rowLocation).Visible = "on";
                task.InputVariableWorkspace(rowLocation).Value = 'select from workspace';
            end
        end
        function addVariableRowUpdate(task,src,~,controlsToActOn)
            addVariableRow(task, src, controlsToActOn)
        end
        function addVariableRow(task, src, controlsToActOn)
            if controlsToActOn == "Input"
                if task.NumberInputVariables == 0
                    task.NumberInputVariables = task.NumberInputVariables + 1;
                    task.InputVariableNameEdit.Enable = "on";
                    task.InputVariableValue.Enable = "on";
                    task.InputVariableWorkspace.Enable = "on";
                    task.InputVariableLiteralEdit.Enable = "on";
                    task.InputVariableRemoveButton.Enable = "on";
                    return;
                end
                task.InputVariablesGrid.RowHeight = [task.InputVariablesGrid.RowHeight, 22];

                task.NumberInputVariables = task.NumberInputVariables + 1;
                newRowLocation = src.Layout.Row + 1;

                % Add new item to the end
                task.InputVariableLabel(end+1) = uilabel(task.InputVariablesGrid,"Text","Input variable");
                task.InputVariableValue(end+1) = uidropdown("Parent",task.InputVariablesGrid,"Items",{'MATLAB variable','Literal value'},...
                    "ValueChangedFcn",@task.updateRowVariableSelection);
                task.InputVariableWorkspace(end+1) = uidropdown("Parent",task.InputVariablesGrid,"Items",{'select from workspace'},...
                    "DropDownOpeningFcn",@task.populateWorkspace,"ValueChangedFcn",...
                    @task.prefillPythonVariableName);
                task.InputVariableLiteralEdit(end+1) = uieditfield(task.InputVariablesGrid,'Visible','off',...
                    "ValueChangedFcn",@task.updateControls);
                task.InputVariableLiteralEdit(end).Layout.Column = task.InputVariableLiteralEdit(end).Layout.Column-1;
                task.InputVariableArrow(end+1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","arrow-right.png"));
                task.InputVariableLiteralEdit(end).Layout.Column = task.InputVariableWorkspace(end).Layout.Column;
                task.PythonVariableNameLabel(end+1) = uilabel(task.InputVariablesGrid,"Text","Python variable name");
                task.InputVariableNameEdit(end+1) = uieditfield(task.InputVariablesGrid,"ValueChangedFcn",@task.updateControls);
                task.InputVariableRemoveButton(end+1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","minus.png"),...
                    "ImageClickedFcn",{@task.removeVariableRowUpdate,"Input"});
                task.InputVariableAddButton(end+1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","plus.png"),...
                    "ImageClickedFcn",{@task.addVariableRowUpdate,"Input"});
                task.InputVariableUpButton(end+1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","up.png"),...
                    "ImageClickedFcn",{@task.moveVariableRowUpdate,"Input"});
                task.InputVariableDownButton(end+1) = uiimage(task.InputVariablesGrid,"ImageSource",fullfile("images","down.png"),...
                    "ImageClickedFcn",{@task.moveVariableRowUpdate,"Input"});

                % Move item contents to emulate row insertion
                [task.InputVariableValue(newRowLocation+1:end).Value] = task.InputVariableValue(newRowLocation:end-1).Value;
                tmp = {task.InputVariableWorkspace(newRowLocation:end-1).Value};
                [task.InputVariableWorkspace(newRowLocation+1:end).Items] = task.InputVariableWorkspace(newRowLocation:end-1).Items;
                [task.InputVariableWorkspace(newRowLocation+1:end).Value] = tmp{:};
                [task.InputVariableWorkspace(newRowLocation+1:end).Visible] = task.InputVariableWorkspace(newRowLocation:end-1).Visible;
                [task.InputVariableLiteralEdit(newRowLocation+1:end).Value] = task.InputVariableLiteralEdit(newRowLocation:end-1).Value;
                [task.InputVariableLiteralEdit(newRowLocation+1:end).Visible] = task.InputVariableLiteralEdit(newRowLocation:end-1).Visible;
                [task.InputVariableNameEdit(newRowLocation+1:end).Value] = task.InputVariableNameEdit(newRowLocation:end-1).Value;

                % New row should be empty
                task.InputVariableValue(newRowLocation).Value = task.InputVariableValue(newRowLocation).Items{1};
                task.InputVariableWorkspace(newRowLocation).Items = task.InputVariableWorkspace(newRowLocation).Items(1);
                task.InputVariableWorkspace(newRowLocation).Value = task.InputVariableWorkspace(newRowLocation).Items{1};
                task.InputVariableWorkspace(newRowLocation).Visible = "on";
                task.InputVariableLiteralEdit(newRowLocation).Visible = "off";
                task.InputVariableLiteralEdit(newRowLocation).Value = "";
                task.InputVariableNameEdit(newRowLocation).Value = "";

                % Emulate new row being added for up-down buttons
                task.InputVariableDownButton(1).Enable = "on";
                if task.NumberInputVariables > 2
                    task.InputVariableDownButton(end-1).Enable = "on";
                end
                task.InputVariableDownButton(end).Enable = "off";
            else
                if task.NumberOutputVariables == 0
                    task.NumberOutputVariables = task.NumberOutputVariables + 1;
                    task.OutputVariableNameEdit.Enable = "on";
                    task.OutputVariableAddButton.Enable = "on";
                    task.OutputVariableRemoveButton.Enable = "on";
                    return
                end
                task.OutputVariablesGrid.RowHeight = [task.OutputVariablesGrid.RowHeight, 22];

                task.NumberOutputVariables = task.NumberOutputVariables + 1;
                newRowLocation = src.Layout.Row + 1;

                % Add new item to the end
                task.OutputVariableLabel(end+1) = uilabel(task.OutputVariablesGrid,"Text","Python variable name");
                task.OutputVariableNameEdit(end+1) = uieditfield(task.OutputVariablesGrid,"ValueChangedFcn",@task.updateControls);
                task.OutputVariableRemoveButton(end+1) = uiimage(task.OutputVariablesGrid, ...
                    "ImageSource",fullfile("images","minus.png"),"ImageClickedFcn",{@task.removeVariableRowUpdate,"Output"});
                task.OutputVariableAddButton(end+1) = uiimage(task.OutputVariablesGrid, ...
                    "ImageSource",fullfile("images","plus.png"),"ImageClickedFcn",{@task.addVariableRowUpdate,"Output"});
                task.OutputVariableUpButton(end+1) = uiimage(task.OutputVariablesGrid, ...
                    "ImageSource",fullfile("images","up.png"),"ImageClickedFcn",{@task.moveVariableRowUpdate,"Output"});
                task.OutputVariableDownButton(end+1) = uiimage(task.OutputVariablesGrid, ...
                    "ImageSource",fullfile("images","down.png"),"ImageClickedFcn",{@task.moveVariableRowUpdate,"Output"});

                % Move item contents to emulate row insertion
                [task.OutputVariableNameEdit(newRowLocation+1:end).Value] = task.OutputVariableNameEdit(newRowLocation:end-1).Value;

                % New row should be empty
                task.OutputVariableNameEdit(newRowLocation).Value = "";

                % Emulate new row being added for up-down buttons
                task.OutputVariableDownButton(1).Enable = "on";
                if task.NumberOutputVariables > 2
                    task.OutputVariableDownButton(end-1).Enable = "on";
                end
                task.OutputVariableDownButton(end).Enable = "off";
            end
        end
        function removeVariableRowUpdate(task, src, ~, controlsToActOn)
            removeVariableRow(task, src, controlsToActOn)
            updateControls(task);
        end
        function removeVariableRow(task, src, controlsToActOn)
            if controlsToActOn == "Input"
                if task.NumberInputVariables == 1
                    task.InputVariableValue.Items = {'MATLAB variable', 'Literal value'};
                    task.InputVariableValue.Value = {'MATLAB variable'};
                    task.InputVariableWorkspace.Items = {'select from workspace'};
                    task.InputVariableWorkspace.Visible = "on";
                    task.InputVariableWorkspace.Enable = "off";
                    task.InputVariableLiteralEdit.Value = '';
                    task.InputVariableLiteralEdit.Enable = "off";
                    task.InputVariableLiteralEdit.Visible = "off";
                    task.InputVariableNameEdit.Value = '';
                    task.InputVariableNameEdit.Enable = "off";
                    task.InputVariableValue.Enable = "off";
                    task.InputVariableRemoveButton.Enable = "off";
                    task.InputVariableUpButton.Enable = "off";
                    task.InputVariableDownButton.Enable = "off";
                else
                    % Identify row to delete
                    rowToDelete = src.Layout.Row;

                    % Move item contents to emulate row deletion
                    [task.InputVariableValue(rowToDelete:end-1).Value] = task.InputVariableValue(rowToDelete+1:end).Value;
                    tmp = {task.InputVariableWorkspace(rowToDelete+1:end).Value};
                    [task.InputVariableWorkspace(rowToDelete:end-1).Items] = task.InputVariableWorkspace(rowToDelete+1:end).Items;
                    [task.InputVariableWorkspace(rowToDelete:end-1).Value] = tmp{:};
                    [task.InputVariableWorkspace(rowToDelete:end-1).Visible] = task.InputVariableWorkspace(rowToDelete+1:end).Visible;
                    [task.InputVariableLiteralEdit(rowToDelete:end-1).Value] = task.InputVariableLiteralEdit(rowToDelete+1:end).Value;
                    [task.InputVariableLiteralEdit(rowToDelete:end-1).Visible] = task.InputVariableLiteralEdit(rowToDelete+1:end).Visible;
                    [task.InputVariableNameEdit(rowToDelete:end-1).Value] = task.InputVariableNameEdit(rowToDelete+1:end).Value;

                    % Delete last row
                    task.InputVariableLabel(end) = []; 
                    task.InputVariableValue(end) = [];
                    task.InputVariableWorkspace(end) = [];
                    task.InputVariableLiteralEdit(end) = [];
                    task.InputVariableArrow(end) = [];
                    task.PythonVariableNameLabel(end) = [];
                    task.InputVariableNameEdit(end) = [];
                    task.InputVariableAddButton(end) = [];
                    task.InputVariableRemoveButton(end) = [];
                    task.InputVariableUpButton(end) = [];
                    task.InputVariableDownButton(end) = [];

                    delete(task.InputVariablesGrid.Children(end-10:end)); % end-10: additional hidden control
                    task.InputVariablesGrid.RowHeight(end) = [];

                    % Emulate new row being deleted for up-down buttons
                    task.InputVariableDownButton(end).Enable = 'off';
                end
                task.NumberInputVariables = task.NumberInputVariables - 1;
            else % controlsToActOn == "Output"
                if task.NumberOutputVariables == 1
                    task.OutputVariableNameEdit.Value = '';
                    task.OutputVariableNameEdit.Enable = "off";
                    task.OutputVariableRemoveButton.Enable = "off";
                    task.OutputVariableUpButton.Enable = "off";
                    task.OutputVariableDownButton.Enable = "off";
                else
                    % Identify row to delete
                    rowToDelete = src.Layout.Row;

                    % Move item contents to emulate row deletion
                    [task.OutputVariableNameEdit(rowToDelete:end-1).Value] = task.OutputVariableNameEdit(rowToDelete+1:end).Value;

                    % Delete last row
                    task.OutputVariableLabel(end) = []; 
                    task.OutputVariableNameEdit(end) = [];
                    task.OutputVariableAddButton(end) = [];
                    task.OutputVariableRemoveButton(end) = [];
                    task.OutputVariableDownButton(end) = [];
                    task.OutputVariableUpButton(end) = [];

                    delete(task.OutputVariablesGrid.Children(end-5:end));
                    task.OutputVariablesGrid.RowHeight(end) = [];

                    % Emulate new row being deleted for up-down buttons
                    task.OutputVariableDownButton(end).Enable = 'off';
                end
                task.NumberOutputVariables = task.NumberOutputVariables - 1;
            end
        end
        function moveVariableRowUpdate(task,src,~,controlsToActOn)
            moveVariableRow(task, src, controlsToActOn)
            updateControls(task);
        end
        function moveVariableRow(task,src,controlsToActOn)
            rowLocation = src.Layout.Row;
            [~,buttonType,~] = fileparts(src.ImageSource);
            if controlsToActOn == "Input"
                if ~(rowLocation == 1 && buttonType == "up") && ~(rowLocation == task.NumberInputVariables && buttonType == "down")
                    if buttonType == "up"
                        % Move item contents to emulate row up
                        [task.InputVariableValue([rowLocation-1,rowLocation]).Value] = task.InputVariableValue([rowLocation,rowLocation-1]).Value;
                        tmp = {task.InputVariableWorkspace([rowLocation,rowLocation-1]).Value};
                        [task.InputVariableWorkspace([rowLocation-1,rowLocation]).Items] = task.InputVariableWorkspace([rowLocation,rowLocation-1]).Items;
                        [task.InputVariableWorkspace([rowLocation-1,rowLocation]).Value] = tmp{:};
                        [task.InputVariableWorkspace([rowLocation-1,rowLocation]).Visible] = task.InputVariableWorkspace([rowLocation,rowLocation-1]).Visible;
                        [task.InputVariableLiteralEdit([rowLocation-1,rowLocation]).Value] = task.InputVariableLiteralEdit([rowLocation,rowLocation-1]).Value;
                        [task.InputVariableLiteralEdit([rowLocation-1,rowLocation]).Visible] = task.InputVariableLiteralEdit([rowLocation,rowLocation-1]).Visible;
                        [task.InputVariableNameEdit([rowLocation-1,rowLocation]).Value] = task.InputVariableNameEdit([rowLocation,rowLocation-1]).Value;
                    else % buttonType == "down"
                        [task.InputVariableValue([rowLocation,rowLocation+1]).Value] = task.InputVariableValue([rowLocation+1,rowLocation]).Value;
                        tmp = {task.InputVariableWorkspace([rowLocation+1,rowLocation]).Value};
                        [task.InputVariableWorkspace([rowLocation,rowLocation+1]).Items] = task.InputVariableWorkspace([rowLocation+1,rowLocation]).Items;
                        [task.InputVariableWorkspace([rowLocation,rowLocation+1]).Value] = tmp{:};
                        [task.InputVariableWorkspace([rowLocation,rowLocation+1]).Visible] = task.InputVariableWorkspace([rowLocation+1,rowLocation]).Visible;
                        [task.InputVariableLiteralEdit([rowLocation,rowLocation+1]).Value] = task.InputVariableLiteralEdit([rowLocation+1,rowLocation]).Value;
                        [task.InputVariableLiteralEdit([rowLocation,rowLocation+1]).Visible] = task.InputVariableLiteralEdit([rowLocation+1,rowLocation]).Visible;
                        [task.InputVariableNameEdit([rowLocation,rowLocation+1]).Value] = task.InputVariableNameEdit([rowLocation+1,rowLocation]).Value;
                    end
                end
            else % controlsToActOn == "Output"
                if ~(rowLocation == 1 && buttonType == "up") && ~(rowLocation == task.NumberOutputVariables && buttonType == "down")
                    if buttonType == "up"
                        % Move item contents to emulate row up
                        [task.OutputVariableNameEdit([rowLocation-1,rowLocation]).Value] = task.OutputVariableNameEdit([rowLocation,rowLocation-1]).Value;
                    else % buttonType == "down"
                        [task.OutputVariableNameEdit([rowLocation,rowLocation+1]).Value] = task.OutputVariableNameEdit([rowLocation+1,rowLocation]).Value;
                    end
                end

            end
        end
        function populateWorkspace(~, src, ~)
            wkspc = evalin('base','whos');
            src.Items = {'select from workspace', wkspc.name};
        end
        function prefillPythonVariableName(task, src, ~)
            tentativeName = src.Value;
            if tentativeName ~= "select from workspace"
                pyDir = evalc('pyrun("print(dir())")');
                pyDir = erase(strsplit(pyDir(1:end-1), "', '"),{'''','[',']'});
                tentativeNameInPyDir = any(matches(pyDir, tentativeName));

                if tentativeNameInPyDir
                    % Same value?
                    tentativeValue = pyrun("",tentativeName);
                    workspaceVariableValue = evalin('base',src.Value);
                    if workspaceVariableValue ~= tentativeValue
                        newPyDir = matlab.lang.makeUniqueStrings([pyDir,tentativeName]);
                        tentativeName = newPyDir{end};
                        warning("MATLAB:RunPythonTask:ExistingPythonVariable",...
                            "Variable will be named '" + tentativeName + ...
                            "' to avoid overwriting existing variable in Python workspace.")
                    end
                end
                task.InputVariableNameEdit(src.Layout.Row).Value = tentativeName;
                updateControls(task);
            end
        end
        function setControlsToDefault(task)
            task.InputSelectFile.Visible = "off";
            task.InputCodeFileLabel.Visible = "off";
            task.InputCodeLabel.Visible = "on";
            task.InputCode.Visible = "on";
            task.InputCode.Value = "";
            task.PythonCodeInputGrid.RowHeight = {'fit',80};
            task.PythonCodeInputGrid.ColumnWidth = {95,500};
            task.InputCode.Layout.Row = [1,2];
            task.InputSelectFile.UserData = [];
            task.InputCodeFileLabel.Text = "No file selected";

            if task.NumberInputVariables > 1
                task.InputVariableLabel(2:end) = [];
                task.InputVariableValue(2:end) = [];
                task.InputVariableWorkspace(2:end) = [];
                task.InputVariableLiteralEdit(2:end) = [];
                task.InputVariableArrow(2:end) = [];
                task.PythonVariableNameLabel(2:end) = [];
                task.InputVariableNameEdit(2:end) = [];
                task.InputVariableAddButton(2:end) = [];
                task.InputVariableRemoveButton(2:end) = [];
                task.InputVariableUpButton(2:end) = [];
                task.InputVariableDownButton(2:end) = [];
            end
            task.InputVariableValue.Value = {'MATLAB variable'};
            task.InputVariableValue.Enable = "off";
            task.InputVariableWorkspace.Items = {'select from workspace'};
            task.InputVariableWorkspace.Value = {'select from workspace'};
            task.InputVariableWorkspace.Visible = "on";
            task.InputVariableWorkspace.Enable = "off";
            task.InputVariableLiteralEdit.Visible = "off";
            task.InputVariableLiteralEdit.Enable = "off";
            task.InputVariableLiteralEdit.Value = "";
            task.InputVariableNameEdit.Value = "";
            task.InputVariableNameEdit.Enable = "off";
            task.InputVariableRemoveButton.Enable = "off";
            task.InputVariableDownButton.Enable = "off";
            task.NumberInputVariables = 0;

            delete(task.InputVariablesGrid.Children(12:end))
            task.InputVariablesGrid.RowHeight = task.InputVariablesGrid.RowHeight(1);

            if task.NumberOutputVariables > 1
                task.OutputVariableLabel(2:end) = [];
                task.OutputVariableNameEdit(2:end) = [];
                task.OutputVariableAddButton(2:end) = [];
                task.OutputVariableRemoveButton(2:end) = [];
                task.OutputVariableUpButton(2:end) = [];
                task.OutputVariableDownButton(2:end) = [];
            end
            delete(task.OutputVariablesGrid.Children(7:end))
            task.OutputVariablesGrid.RowHeight = task.OutputVariablesGrid.RowHeight(1);

            task.OutputVariableNameEdit.Value = "";
            task.OutputVariableNameEdit.Enable = "off";
            task.OutputVariableRemoveButton.Enable = "off";
            task.OutputVariableUpButton.Enable = "off";
            task.OutputVariableDownButton.Enable = "off";

            task.NumberOutputVariables = 0;
        end
    end
    methods (Access = protected)
        function setup(task)
            createComponents(task);
            updateControls(task);
        end
    end
    methods
        function [code, outputs] = generateCode(task)
            % No Python Code
            if (task.SelectCodeButtonGroup.SelectedObject.Text == "Python statements" && ...
                    (length(task.InputCode.Value) == 1 && task.InputCode.Value == "")) || ...
                    (task.SelectCodeButtonGroup.SelectedObject.Text == "Python script file" && ...
                    task.InputCodeFileLabel.Text == "No file selected")
                outputs = {};
                code = '';
                return;
            end

            % Inputs to Python (pyrun or pyrunfile)
            pyRunInputs = [];
            if task.NumberInputVariables > 0
                input.name = {task.InputVariableNameEdit.Value};
                inputsFromWorkspace = [task.InputVariableWorkspace.Visible] == "on";
                input.value(inputsFromWorkspace) = {task.InputVariableWorkspace(inputsFromWorkspace).Value};
                input.value(~inputsFromWorkspace) = {task.InputVariableLiteralEdit(~inputsFromWorkspace).Value};
                specifiedNameValue = input.name ~= "" & (input.value ~= "select from workspace" & input.value ~= "");
                pyRunInputs = [pyRunInputs, char(strjoin("""" + string(input.name(specifiedNameValue)) + ...
                    """" + ', ' + string(input.value(specifiedNameValue)),", "))];
            end

            % Outputs to Python (pyrun or pyrunfile)
            pyRunOutputs = [];
            if task.NumberOutputVariables > 0
                output.name = {task.OutputVariableNameEdit.Value};
                specifiedNameValue = output.name ~= "";
                               
                outputs = matlab.lang.makeValidName(output.name(specifiedNameValue),'replacementstyle','delete');
                if ~isempty(outputs)
                    if length(outputs) > 1
                        code = ['[' char(strjoin(outputs,', ')),'] = '];
                        pyRunOutputs = ['["' char(strrep(strjoin(deblank(output.name(specifiedNameValue)), '", "'), '"', '"')) '"]'];
                    else
                        code = [char(outputs),' = '];
                        pyRunOutputs = ['"' char(deblank(output.name(specifiedNameValue))) '"'];
                    end
                end
            else
                outputs = {};
            end

            if isempty(outputs)
                code = [];
            end

            if length(outputs) == 1
                outputs = {char(outputs)};
            end

            % pyrun or pyrunfile
            if task.SelectCodeButtonGroup.SelectedObject.Text == "Python statements" % pyrun
                codeprefix = '% Running Python statements from Live Task';
                codeprefix = [codeprefix, newline];
                
                pythonCodeBlock = deblank(regexprep(string(task.InputCode.Value),'"','""'));
                if length(pythonCodeBlock) > 1
                    spaces = repmat(' ', 1, 4);
                    pythonCode = 'pythonCode';
                    pythonCodeBlock = [pythonCode, ' = [', newline, spaces, '"', ...
                        char(strjoin(pythonCodeBlock, ['"', newline, spaces, '"'])), '"', ...
                        newline, spaces, '];', newline];
                else
                    pythonCode = ['"', char(pythonCodeBlock), '"'];
                    pythonCodeBlock = '';
                end
                code = [codeprefix, pythonCodeBlock, code, 'pyrun(', pythonCode];
            else % pyrunfile
                codeprefix = '% Running Python script file from Live Task';
                codeprefix = [codeprefix, newline];

                code = [code,'pyrunfile('];               
                code = [codeprefix, code, '"', task.InputCodeFileLabel.Text, '"'];
            end

            if ~isempty(pyRunOutputs)
                code = [code,', ',pyRunOutputs];
            end
            if ~isempty(pyRunInputs)
                code = [code, ', ', pyRunInputs];
            end
            code = [code, ');'];
        end
        function summary = get.Summary(task)
            if task.SelectCodeButtonGroup.SelectedObject.Text == "Python statements"
                summary = 'Run Python statements';
            else
                summary = 'Run Python script file';
                [~,name,ext] = fileparts(task.InputCodeFileLabel.Text);
                if name ~= "No file selected"
                    summary = [summary, ' (', name, ext, ')'];
                end
            end
        end 
        function state = get.State(task)
            state = struct();
            state.PyrunfileButton.Value = task.PyrunfileButton.Value;

            state.InputCodeLabel.Visible = task.InputCodeLabel.Visible;
            state.InputCodeFileLabel.Text = task.InputCodeFileLabel.Text;
            state.InputCodeFileLabel.Visible = task.InputCodeFileLabel.Visible;

            state.InputCode.Value = task.InputCode.Value;
            state.InputCode.Visible = task.InputCode.Visible;
            state.InputCode.Layout.Row = task.InputCode.Layout.Row;

            state.InputSelectFile.Visible = task.InputSelectFile.Visible;
            state.PythonCodeInputGrid.ColumnWidth = task.PythonCodeInputGrid.ColumnWidth;
            state.PythonCodeInputGrid.RowHeight = task.PythonCodeInputGrid.RowHeight;

            state.InputVariableWorkspace.Items = {task.InputVariableWorkspace.Items};

            state.NumberInputVariables = task.NumberInputVariables;
            state.InputVariableValue.Value = {task.InputVariableValue.Value};
            state.InputVariableWorkspace.Value = {task.InputVariableWorkspace.Value};
            state.InputVariableLiteralEdit.Value = {task.InputVariableLiteralEdit.Value};
            state.InputVariableNameEdit.Value = {task.InputVariableNameEdit.Value};

            state.InputVariableValue.Visible = {task.InputVariableValue.Visible};
            state.InputVariableWorkspace.Visible = {task.InputVariableWorkspace.Visible};
            state.InputVariableLiteralEdit.Visible = {task.InputVariableLiteralEdit.Visible};
            state.InputVariableNameEdit.Visible = {task.InputVariableNameEdit.Visible};
            state.InputVariableAddButton.Visible = {task.InputVariableAddButton.Visible};
            state.InputVariableRemoveButton.Visible = {task.InputVariableRemoveButton.Visible};
            state.InputVariableUpButton.Visible = {task.InputVariableUpButton.Visible};
            state.InputVariableDownButton.Visible = {task.InputVariableDownButton.Visible};

            state.NumberOutputVariables = task.NumberOutputVariables;
            state.OutputVariableNameEdit.Value = {task.OutputVariableNameEdit.Value};
        end
        function set.State(task, state)
            task.PyrunfileButton.Value = state.PyrunfileButton.Value;

            task.InputCodeLabel.Visible = state.InputCodeLabel.Visible;
            task.InputCodeFileLabel.Text = state.InputCodeFileLabel.Text;
            task.InputCodeFileLabel.Visible = state.InputCodeFileLabel.Visible;

            task.InputCode.Value = state.InputCode.Value;
            task.InputCode.Visible = state.InputCode.Visible;
            task.InputCode.Layout.Row = state.InputCode.Layout.Row;

            task.InputSelectFile.Visible = state.InputSelectFile.Visible;
            task.PythonCodeInputGrid.ColumnWidth = state.PythonCodeInputGrid.ColumnWidth;
            task.PythonCodeInputGrid.RowHeight = state.PythonCodeInputGrid.RowHeight;

            task.NumberInputVariables = 0;
            if state.NumberInputVariables >= 1
                task.InputVariableNameEdit.Enable = "on";
                task.InputVariableValue.Enable = "on";
                task.InputVariableWorkspace.Enable = "on";
                task.InputVariableLiteralEdit.Enable = "on";
                task.InputVariableRemoveButton.Enable = "on";
                for i = 1:state.NumberInputVariables
                    addVariableRow(task,task.InputVariableAddButton(1),"Input")
                end
            end

            [task.InputVariableValue.Value] = state.InputVariableValue.Value{:};
            [task.InputVariableWorkspace.Items] = state.InputVariableWorkspace.Items{:};
            [task.InputVariableWorkspace.Value] = state.InputVariableWorkspace.Value{:};
            [task.InputVariableLiteralEdit.Value] = state.InputVariableLiteralEdit.Value{:};
            [task.InputVariableNameEdit.Value] = state.InputVariableNameEdit.Value{:};
            [task.InputVariableValue.Visible] = state.InputVariableValue.Visible{:};
            [task.InputVariableWorkspace.Visible] = state.InputVariableWorkspace.Visible{:};
            [task.InputVariableLiteralEdit.Visible] = state.InputVariableLiteralEdit.Visible{:};
            [task.InputVariableNameEdit.Visible] = state.InputVariableNameEdit.Visible{:};

            [task.InputVariableValue.Visible] = state.InputVariableValue.Visible{:};
            [task.InputVariableWorkspace.Visible] = state.InputVariableWorkspace.Visible{:};
            [task.InputVariableLiteralEdit.Visible] = state.InputVariableLiteralEdit.Visible{:};
            [task.InputVariableNameEdit.Visible] = state.InputVariableNameEdit.Visible{:};
            [task.InputVariableAddButton.Visible] = state.InputVariableAddButton.Visible{:};
            [task.InputVariableRemoveButton.Visible] = state.InputVariableRemoveButton.Visible{:};
            [task.InputVariableUpButton.Visible] = state.InputVariableUpButton.Visible{:};
            [task.InputVariableDownButton.Visible] = state.InputVariableDownButton.Visible{:};

            task.NumberOutputVariables = 0;
            if state.NumberOutputVariables >= 1
                task.OutputVariableNameEdit.Enable = "on";
                task.OutputVariableAddButton.Enable = "on";
                task.OutputVariableRemoveButton.Enable = "on";
                for i = 1:state.NumberOutputVariables
                    addVariableRow(task,task.OutputVariableAddButton(1),"Output")
                end
            end

            [task.OutputVariableNameEdit.Value] = state.OutputVariableNameEdit.Value{:};
        end
        function reset(task)
            setControlsToDefault(task)
        end
    end
end