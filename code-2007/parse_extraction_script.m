function episodes = parse_extraction_script( extraction_script )

episodes = [];
f = fopen(extraction_script,'r');
inentry = 0;
while ~feof(f)
    line = strtrim(fgetl(f));
    if ~isempty(line) && line(1)~='#'        
        [section,value] = strtok(line,':');
        assert(~isempty(value), ['invalid line --> ' line]);

        value = strtrim(value(2:end));
        switch lower(strtrim(section))
            case 'episode id'
                if inentry
                    validate_episode( episode );
                    episodes = [episodes episode];
                end
                clear episode;
                episode.id = value;
                episode.channels = [];
                inentry = 1;
            case 'type'
                episode.type = value;   
            case 'source'
                episode.source_file = value;  
            case 'time range'
                [r1,r2] = strtok(value,'-');
                episode.timerange = [str2num(r1),str2num(r2(2:end))];
            case 'channel'
                clear channel;
                assert( sum(value == ':')==4, ['Channel spec must have 5 fields in entry - ' value] );
                [channel.name ,value] = strtok(value,       ':');
                channel.name = strtrim(channel.name);
                [channel.role, value] = strtok(value(2:end),':');
        		channel.role = upper( strtrim( channel.role ) );
            	assert(length(channel.role)==1 && ismember(channel.role,'DSN') ...
                    , ['Channel role must be D, S, or N - ' value] );               
                [channel.sensor_xy,value] = strtok(value(2:end),':');
                channel.sensor_xy = strread(channel.sensor_xy,'','delimiter',',');
                [channel.gain, value] = strtok(value(2:end),':');
                channel.gain = str2num(channel.gain);
                channel.mix = strread(value(2:end),'','delimiter',',');
                episode.channels = [episode.channels channel];
            otherwise
                error(['invalid section: ' section]);
        end
    end
end

if inentry 
    validate_episode( episode );
    episodes = [episodes episode];
end
fclose(f);





function validate_episode( episode )
fprintf('\nParsing  %s\n', episode.id);

% Errors for missing required fields
assert( isfield(episode,'id'         ), 'Missing episode id'         );
assert( isfield(episode,'source_file'), 'Missing source filename'    );
assert( isfield(episode,'type'       ), 'Missing file type'          ); 
assert( isfield(episode,'timerange'  ), 'Missing time range'         );
assert( isfield(episode,'channels') ...
    && ~isempty( episode.channels ), 'Missing channel information');
