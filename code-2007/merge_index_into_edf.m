function merge_index_into_edf( output_file, index_file, index_name )
% merge_index_into_edf( output_edf_file, index_file, index_name )
% adds the index in index_file and adds it as a channel in output_edf_file

tmpfile = 'temp.edf';
hdr = edfopen( output_file );
fout = fopen( tmpfile, 'w','ieee-le');
assert( fout ~= -1, ['Could not open ' tmpfile ]);

% read the entire index
% read metrics
fmetrics = fopen  ( index_file, 'r');
assert( fmetrics ~= -1,  ['Could not open ' index_file] );
line = fgetl(fmetrics);  %throw away first line
metrics = [];
while ~feof(fmetrics)
    metrics = [metrics; str2num( fgetl(fmetrics) )];
end
fclose(fmetrics);

% create header 
write_header_with_added_channel( fout, hdr, index_name );

% create data 
samples_per_frame = hdr.samples_per_second*hdr.frame_duration;
for n=0:hdr.nframes-1
    block = edfread( hdr, n*samples_per_frame, hdr.samples_per_frame );
    t = n*samples_per_frame+(1:hdr.samples_per_frame)-1;
    g = interp1(metrics(:,1),metrics(:,2),t,'linear');
    g(find(isnan(g)))=0;
    block = [block; g];
    fwrite( fout, block', 'int16');
end
fclose( fout );
% overwrite initial file with the merged file
movefile(tmpfile,output_file,'f');





function write_header_with_added_channel( fid, hdr, index_name )

fwrite( fid, '0       ', 'uchar' );
fwrite( fid, strjust(sprintf('%80s','wiped clean'),'left'), 'uchar' );
fwrite( fid, strjust(sprintf('%80s','wiped clean'),'left'), 'uchar' );
fwrite( fid, hdr.start_date, 'uchar' );
fwrite( fid, hdr.start_time, 'uchar' );

header_size = 8 + 80 + 80 + 8 + 8 + 8 + 44 + 8 + 8 + 4 ...
    + (hdr.nchannels+1)*(16 + 80 + 8 + 8 + 8 + 8 + 8 + 80 + 8 + 32 );

fwrite( fid, strjust(sprintf('%8d',header_size),'left'), 'uchar' );
fwrite( fid, repmat(' ',44,1), 'uchar'); %blank reserved field
fwrite( fid, strjust(sprintf('%8d',hdr.nframes),'left') , 'uchar' );
fwrite( fid, strjust(sprintf('%8f',hdr.frame_duration),'left'), 'uchar' );
fwrite( fid, strjust(sprintf('%4d',hdr.nchannels+1),'left' ) , 'uchar' );

channelnames = [hdr.channelnames; strjust( sprintf('%16s',index_name), 'left' )];
fwrite( fid, channelnames', 'uchar' );

% duplicate the last channel entry 
fwrite( fid, hdr.transducer([1:end end],:)', 'uchar' );
fwrite( fid, hdr.physdime  ([1:end end],:)', 'uchar' );
fwrite( fid, hdr.physmin   ([1:end end],:)', 'uchar' );
fwrite( fid, hdr.physmax   ([1:end end],:)', 'uchar' );
fwrite( fid, hdr.digimin   ([1:end end],:)', 'uchar' );
fwrite( fid, hdr.digimax   ([1:end end],:)', 'uchar' );
fwrite( fid, hdr.prefilt   ([1:end end],:)', 'uchar' );
rate = strjust( sprintf('%8d',round(hdr.samples_per_frame)),'left');
fwrite( fid, repmat( rate, hdr.nchannels+1, 1 )', 'uchar');

% reserved field containing channel role and sensor xy positions
for i=1:hdr.nchannels
    fwrite( fid, [hdr.roles(i) ')' strjust(sprintf('%30s',num2str(round(hdr.sensorxy(i,:)))), 'left')]);
end
fwrite( fid, ['D)',strjust(sprintf('%30s','0 0'))]);
assert( ftell(fid)==header_size, 'Header_size does not match file position');

