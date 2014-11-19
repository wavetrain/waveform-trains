function filenames = make_filenames( episode_id, execution_id, index_id )

% generate all filenames that are used in 
filenames.folder       = ['./episodes/' episode_id ];
filenames.signal_file  = [filenames.folder '/original.edf'];
filenames.output_file  = [filenames.folder '/' execution_id '.edf'];
filenames.train_file   = [filenames.folder '/' execution_id '_' index_id '.trains' ];
filenames.metrics_file = [filenames.folder '/' execution_id '_' index_id '_metrics.csv' ];
filenames.figures      = [filenames.folder '/' execution_id '_' index_id '_figure' ];