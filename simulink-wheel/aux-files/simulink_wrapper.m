function outputMatrix = simulink_wrapper(inputMatrix, configJson)
    mdl = "simulink_model_example";

    %---------------------------------------------------------------
    % 1. Parse JSON configuration (if provided)
    %    Config values are applied as model workspace variables
    %---------------------------------------------------------------
    if nargin < 2 || isempty(configJson)
        config = struct();
    else
        try
            config = jsondecode(configJson);
        catch ME
            fprintf("Warning: Failed to parse config JSON: %s. Using empty config.\n", ME.message);
            config = struct();
        end
    end

    % Print first config received (for debugging)
    persistent config_printed
    if isempty(config_printed)
        config_printed = true;
        fprintf("First config received:\n");
        disp(config);
    end

    %---------------------------------------------------------------
    % 2. Extract time and input signals from input matrix
    %    Assumes inputMatrix = [time, signal1, signal2, ..., signalN]
    %---------------------------------------------------------------
    t = inputMatrix(:,1);         % Time vector
    u = inputMatrix(:,2:end);     % Signal values
    n_signals = size(u,2);        % Number of input signals

    %---------------------------------------------------------------
    % 3. Build Dataset object
    %    Timeseries order must match Inport order in the Simulink model
    %---------------------------------------------------------------
    inports = Simulink.SimulationData.Dataset;
    for i = 1:n_signals
        signal = timeseries(u(:,i), t);
        inports = inports.addElement(signal);  % No name needed
    end

    %------------------------------------------------------------------
    % 4. Configure SimulationInput object (efficient for repeated calls)
    %------------------------------------------------------------------
    % Use a persistent SimulationInput object to avoid recompilation
    persistent s0_loaded
    if isempty(s0_loaded)
        fprintf("Compiling model...\n")
        s0 = Simulink.SimulationInput(mdl);

        % Configure for deployment (Rapid Accelerator + safe options)
        % This prepares the model for repeated high-performance execution
        s0 = simulink.compiler.configureForDeployment(s0);

        s0_loaded = s0;
        fprintf("Compiled\n")
    end

    % Clone and update external inputs for this specific run
    s = s0_loaded.setExternalInput(inports);

    % Set simulation stop time based on last time sample
    s = s.setModelParameter("StopTime", num2str(t(end)));

    %------------------------------------------------------------------
    % 5. Apply JSON config as model variables
    %    Each field in the config JSON becomes a workspace variable
    %------------------------------------------------------------------
    if isstruct(config)
        configFields = fieldnames(config);
        for i = 1:numel(configFields)
            paramName = configFields{i};
            paramValue = config.(paramName);
            try
                s = s.setVariable(paramName, paramValue);
            catch ME
                fprintf("Warning: Failed to set variable '%s': %s\n", paramName, ME.message);
            end
        end
    end

    %------------------------------------------------------------------
    % 6. Run the simulation
    %------------------------------------------------------------------
    out = sim(s);
    % Only print sim output once
    persistent sim_0
    if isempty(sim_0)
        sim_0 = out;
        fprintf("Sim ouput:\n")
        disp(sim_0)
        fprintf("Sim yout:\n")
        disp(sim_0.yout)
    end
    yout = out.yout; 

    %---------------------------------------------------------------
    % 7. Extract full output signal values into a matrix [n_times x total_output_width]
    %---------------------------------------------------------------
    if isa(yout, 'Simulink.SimulationData.Dataset')
        n_outputs = yout.numElements;
        outputMatrix = [];
        for i = 1:n_outputs
            data = yout{i}.Values.Data;
            outputMatrix = [outputMatrix, data];
        end
    
    elseif isnumeric(yout)
        % yout is already [n_times x n_outputs]
        outputMatrix = yout;
    
    elseif isstruct(yout)
        % Structure with time format
        n_outputs = numel(yout.signals);
        outputMatrix = [];
        for i = 1:n_outputs
            data = yout.signals(i).values;
            outputMatrix = [outputMatrix, data];
        end
    else
        error('Unexpected yout type: %s', class(yout));
    end
    
    persistent outputMatrix_0
    if isempty(outputMatrix_0)
        outputMatrix_0 = outputMatrix;
        fprintf("First outputMatrix:\n")
        disp(outputMatrix_0)
    end

end
