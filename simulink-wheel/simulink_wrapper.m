function outputMatrix = simulink_wrapper(inputMatrix)
    mdl = "simulink_example_inports";

    %---------------------------------------------------------------
    % 1. Extract time and input signals from input matrix
    %    Assumes inputMatrix = [time, signal1, signal2, ..., signalN]
    %---------------------------------------------------------------
    t = inputMatrix(:,1);         % Time vector
    u = inputMatrix(:,2:end);     % Signal values
    n_signals = size(u,2);        % Number of input signals

    %---------------------------------------------------------------
    % 2. Build Dataset object
    %    Timeseries order must match Inport order in the Simulink model
    %---------------------------------------------------------------
    inports = Simulink.SimulationData.Dataset;
    for i = 1:n_signals
        signal = timeseries(u(:,i), t);
        inports = inports.addElement(signal);  % No name needed
    end

    %------------------------------------------------------------------
    % 3. Configure SimulationInput object (efficient for repeated calls)
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
    % 4. Run the simulation
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
    % 5. Extract full output signal values into a matrix [n_times x total_output_width]
    %---------------------------------------------------------------
    n_outputs = yout.numElements;
    outputMatrix = [];  % Initialize empty matrix
    
    for i = 1:n_outputs
        data = yout{i}.Values.Data;  % Can be [n_times x k]
        
        % On first loop, determine number of time steps
        if i == 1
            n_times = size(data, 1);
        end
        
        % Sanity check: all outputs must share same time base
        if size(data,1) ~= n_times
            error("Inconsistent time dimension in output %d", i)
        end
        
        outputMatrix = [outputMatrix, data];  % Concatenate along columns
    end
    
    persistent outputMatrix_0
    if isempty(outputMatrix_0)
        outputMatrix_0 = outputMatrix;
        fprintf("First outputMatrix:\n")
        disp(outputMatrix_0)
    end

end
