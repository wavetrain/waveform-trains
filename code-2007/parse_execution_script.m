function executions = parse_execution_script( execution_script )
% reads a list of execution records from execution_scrpt and stores them in a cell array 

executions = [];
f = fopen(execution_script,'r');

inentry = 0;
while ~feof(f)
    line = strtrim(fgetl(f));
    if ~isempty(line) && line(1)~='#'
        [section,value] = strtok(line,':');
        assert( ~isempty(value), ['invalid line: ' line]);

        value = strtrim(value(2:end));
        switch lower(strtrim(section))
            case 'execution id'
                if inentry 
                    validate_execution(execution);
                    executions = [executions execution];
                end
                inentry = 1;
                clear execution;
                execution.id = value;
                execution.indices = [];
                
            case 'episodes'
                % read comma-delimited list of episode ids 
                for k=1:inf
                    [episode_id,value] = strtok(value,','); 
                    episode_id = strtrim(episode_id);
                    if isempty(episode_id)
                        break; 
                    end
                    execution.episode_ids{k} = episode_id;
                end

            case 'index'
                % format: 
                % index:<name>:<epoch>,<step>,<ntrains>:<widths>:<trains call>:<metrics call>
                assert(sum(value==':')==4, ['index entry must have five fields - ' value]);
                [index.name,value] = strtok(value,':');
                index.name = strtrim(index.name);
                [wtp_params,value] = strtok(value(2:end),':');
                wtp_params = str2num(wtp_params);
                assert(length(wtp_params)==3,['WTP requires 3 parameters - ' value]);
                index.epoch   = wtp_params(1);
                index.step    = wtp_params(2);
                index.ntrains = wtp_params(3);
                [index.widths, value] = strtok(value(2:end),':');
                index.widths = str2num(index.widths);
                [index.trains_callback,value] = strtok(value(2:end),':');
                index.trains_callback = strtrim( index.trains_callback );
                [index.metrics_callback,value] = strtok(value(2:end),':');
                index.metrics_callback = strtrim( index.metrics_callback );
                execution.indices = [execution.indices index];

            case 'illustrate'
                % format:
                % illustrate: <yes|no> : <list of epoch numbers> 
                [execution.illustrate,value] = strtok(value,':');
                execution.illustrate = strcmpi(strtrim(execution.illustrate),'Yes');
                [execution.illustrate_epochs,value] = strtok(value(2:end),':');
                execution.illustrate_epochs = str2num( execution.illustrate_epochs );
                
            otherwise
                error(['invalid section: ' section]);
        end
    end
end

if inentry
    validate_execution(execution);
    executions = [executions execution];
end

fclose(f);





function validate_execution( execution )

%generate errors for missing required fields 
assert( isfield(execution,'id'          ), 'Missing execution id'   );
assert( isfield(execution,'episode_ids' ), 'Missing episode list'   );   
assert( isfield(execution,'indices' ) && ~isempty(execution.indices), 'missing index');
%generate warnings for missing optional fields 
assert_( isfield(execution,'illustrate'), 'Missing optional illustrate switch');
assert_( isfield(execution,'illustrate_epochs'), 'Missing optional illustrate epochs');