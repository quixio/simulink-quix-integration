function outputMatrix = simulink_wrapper(inputMatrix)
% inputMatrix = [time, u1, u2, ...]
    mdl = "sldemo_engine";

    % 1) Parse inputs
    t = inputMatrix(:,1);
    u = inputMatrix(:,2:end);
    n_signals = size(u,2);

    % 2) External-input Dataset (port order)
    inports = Simulink.SimulationData.Dataset;
    for k = 1:n_signals
        inports = inports.addElement( timeseries(u(:,k), t) );
    end

    % 3) Prepare SimulationInput (persist for speed)
    persistent s0_loaded
    if isempty(s0_loaded)
        fprintf("Compiling model...\n")
        s0 = Simulink.SimulationInput(mdl);
        s0 = simulink.compiler.configureForDeployment(s0);
        % Force consistent outputs
        s0 = s0.setModelParameter( ...
            "SaveOutput","on", ...
            "ReturnWorkspaceOutputs","on", ...
            "SaveFormat","Dataset");

        % Optional: build/update Rapid Accelerator target to silence warnings
        try
            Simulink.BlockDiagram.buildRapidAcceleratorTarget(char(mdl));
        catch, end

        s0_loaded = s0;
        fprintf("Compiled\n")
    end

    % Clone and set run-specific params
    s = s0_loaded.setExternalInput(inports);
    s = s.setModelParameter("StopTime", num2str(t(end)));

    % 4) Simulate
    out = sim(s);

    persistent printed_once
    if isempty(printed_once)
        printed_once = true;
        fprintf("Sim output (once):\n"); disp(out)
        fprintf("Sim yout (once):\n");    disp(out.yout)
    end

    % 5) Extract to numeric matrix
    yout = out.yout;
    if isa(yout, 'Simulink.SimulationData.Dataset')
        outputMatrix = local_dataset_to_matrix(yout, t);
    elseif isnumeric(yout)
        outputMatrix = yout;
    elseif isstruct(yout)
        % Structure with time
        C = cell(1,numel(yout.signals));
        for i = 1:numel(yout.signals)
            C{i} = yout.signals(i).values;
        end
        outputMatrix = cat(2,C{:});
    else
        error('Unexpected yout class: %s', class(yout));
    end

    persistent outputMatrix_0
    if isempty(outputMatrix_0)
        outputMatrix_0 = outputMatrix;
        fprintf("First outputMatrix (once, first 10 rows):\n")
        disp(outputMatrix_0(1:min(10,end), :))
    end
end


% === Helpers ===

function M = local_dataset_to_matrix(ds, targetTime)
% Flatten a Dataset into numeric columns, resampled (ZOH) to targetTime
    n = ds.numElements;
    cols = {};
    for i = 1:n
        elem = ds.getElement(i);   % safer than ds{i}
        vals = elem.Values;
        cols_i = local_values_to_columns(vals, targetTime);
        cols = [cols, cols_i]; %#ok<AGROW>
    end
    if isempty(cols)
        M = zeros(numel(targetTime),0);
    else
        m = size(cols{1},1);
        for k = 2:numel(cols)
            if size(cols{k},1) ~= m
                error('Inconsistent time bases after resampling (element %d).', k);
            end
        end
        M = cat(2, cols{:});
    end
end


function cols = local_values_to_columns(vals, targetTime)
% Convert a "Values" payload into numeric columns at targetTime using ZOH.
% Handles:
%   - scalar timeseries
%   - array of timeseries (vector signals split by channel)
%   - nested Dataset (buses)
%   - timetable

    if isa(vals,'timeseries')
        if isscalar(vals)
            cols = {ts_to_cols(vals, targetTime)};
        else
            % Array of timeseries → loop each element
            cols = cell(1, numel(vals));
            for k = 1:numel(vals)
                cols{k} = ts_to_cols(vals(k), targetTime);
            end
        end

    elseif isa(vals,'Simulink.SimulationData.Dataset')
        % Nested dataset (bus)
        cols = {};
        for j = 1:vals.numElements
            sub = vals.getElement(j);
            subCols = local_values_to_columns(sub.Values, targetTime);
            cols = [cols, subCols]; %#ok<AGROW>
        end

    elseif istimetable(vals)
        % Convert timetable to numeric via nearest/ZOH to targetTime
        % Try to convert row times to seconds relative to the first
        rt = vals.Properties.RowTimes;
        if isduration(rt)
            tt_sec = seconds(rt);
        elseif isdatetime(rt)
            tt_sec = seconds(rt - rt(1));
        else
            error('Unsupported timetable RowTimes class: %s', class(rt));
        end
        data = vals.Variables;
        data = reshape(data, size(data,1), []);
        % ZOH via 'previous' (nearest-left)
        cols = {interp_prev(tt_sec, data, targetTime)};

    else
        error('Unsupported Values class: %s', class(vals));
    end
end


function Y = ts_to_cols(ts, targetTime)
% ZOH resample a scalar timeseries to targetTime without using ts/resample.
    t_src = ts.Time(:);
    X = ts.Data;
    X = reshape(X, size(X,1), []);    % [Ns x nChan]
    % Remove duplicate timestamps (keep last sample)
    [t_unique, ia] = unique(t_src, 'stable');
    X = X(ia, :);

    % If time already matches, skip interpolation
    if numel(t_unique) == numel(targetTime) && all(abs(t_unique - targetTime(:)) < eps(max(1,max(t_unique))))
        Y = X;
        return
    end

    % ZOH using 'previous'; extrapolate using last value
    Y = interp_prev(t_unique, X, targetTime);
end


function Y = interp_prev(t_src, X, t_q)
% Piecewise-constant (zero-order hold) interpolation:
%   for each query time t_q, take the sample at the greatest t_src <= t_q.
%   For t_q before the first sample, use the first value (ZOH extrapolation).
% Vectorized and robust for matrices.
    t_src = t_src(:);
    t_q   = t_q(:);

    % Ensure strictly increasing source time
    [t_src, ia] = unique(t_src, 'stable');
    X = X(ia, :);

    % For speed, use discretize to find left bins
    % edges are t_src with +Inf as a final edge
    edges = [-Inf; t_src(2:end); Inf];
    idx = discretize(t_q, edges);  % idx in 1..numel(t_src)

    % Map idx==0 (shouldn't happen due to -Inf) and any NaNs to 1
    idx(~isfinite(idx) | idx<1) = 1;

    Y = X(idx, :);
end