function process_episodes( execution_script ) 

close all;

executions = parse_execution_script( execution_script );

for execution = executions
    for episode_id = execution.episode_ids
        filenames = make_filenames( episode_id{1}, execution.id, '' );
        copyfile( filenames.signal_file, filenames.output_file );
        
        fprintf('\n== Execution %s: %s\n\n', execution.id, episode_id{1} );
        execution
        for index = execution.indices
            filenames = make_filenames( episode_id{1}, execution.id, index.name );
            
            % call make_trains callback
            disp('extracting trains ... ');
            feval( index.trains_callback, filenames.signal_file, filenames.train_file ...
                , index.epoch, index.step, index.ntrains, index.widths );
            
            % call the make_metrics callback
            disp('computing metrics ... ');
            hdr = edfopen( filenames.signal_file );  % don't need to close
            roles = hdr.roles( find( hdr.roles ~= 'D' ) );
            roles = (roles == 'S') - (roles == 'N');  % 1 for signal, -1 for noise/artifacts
            feval( index.metrics_callback, filenames.train_file ...
                , filenames.metrics_file, roles, index.epoch, hdr.samples_per_second );
            
            % merge signals and metrics
            disp('merging metrics into output edf...');
            merge_index_into_edf( filenames.output_file, filenames.metrics_file, index.name );
            
            if execution.illustrate
                %produce PDF illustrations
                 illustrate( filenames, execution.illustrate_epochs, index.epoch );
            end
        end
    end
end

disp('Done processing episodes');