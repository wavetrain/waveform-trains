function extract_from_edf( episode )
% Extracts a specified episode from and EDF file into a separate EDF file
% The EDF file format is specified at http://www.edfplus.info/specs/edf.html


%check for present of fields
assert( isfield(episode, 'source_file'), 'Episode structure missing source_file' );
assert( isfield(episode, 'signal_file'), 'Episode structure missing signal_file' );
assert( isfield(episode, 'timerange'),'Episode structure missing timerange' );
assert( episode.timerange(1) < episode.timerange(2), 'end_second must be greater than start_second');
assert( isfield(episode, 'channels'), 'Episode structure missing channel information');


%make channel mixing matrix MIX
MIX = [];
for channel=episode.channels
    MIX(end+1,1:length(channel.mix)) = channel.gain*channel.mix; %tolerates variable lengths
end


% identify participating channels
episode.source_channels = find(any( MIX ~= 0 ));
assert( ~isempty( episode.source_channels ), 'The mixing matrix contains no non-zero elements' );


% open source and destination files  
fsrc = fopen(episode.source_file,'r','ieee-le');
assert( fsrc ~= -1, [episode.source_file ' not found']);
fdst = fopen(episode.signal_file,'w','ieee-le');
assert( fdst ~= -1, ['Could not open ' episode.signal_file]); 


% read source header, make and save episode header
hsrc = read_header( fsrc );
assert( max( episode.source_channels ) <= hsrc.nchannels, 'Channel mix exceeds number of channels in source signal' );
hdst = make_episode_header( hsrc, episode );
write_header( fdst, hdst );


%%%%%%%%%%%%%% copy signals %%%%%%%%%%%%%%%%

% tolerates signals of various sample rates except for channels in episode.source_channnels
total_samples_per_frame = sum( hsrc.samples_per_frame' ); 
max_signal = 0;
min_signal = 0;

MIX = MIX(:,episode.source_channels);
idx = cumsum([0 hsrc.samples_per_frame']);
for iframe=hdst.start_frame:hdst.end_frame  % iframe = 0-based frame numbers
    fseek(fsrc,hsrc.header_size+2*iframe*total_samples_per_frame,'bof');
    frame = fread(fsrc,total_samples_per_frame,'int16')';
    signals = [];
    for j=episode.source_channels
        signals = [signals; frame(idx(j)+(1:hsrc.samples_per_frame(j)))];
    end
    signals = MIX*signals;
    assert( all( size( signals ) == [hdst.nchannels, mean(hdst.samples_per_frame)] ), 'Frame size mismatch' );
    max_signal = max( max_signal, max( max( signals ) ) );
    min_signal = min( min_signal, min( min( signals ) ) );
    fwrite( fdst, signals', 'int16' );
end

fclose(fsrc);
fclose(fdst);

%generate warnings for values outside range
assert_(min_signal >  -2048 && max_signal <  2047, 'Signal amplitude outside range');
assert_(min_signal > -32768 && max_signal < 32767, 'Signal is not representable in int16');
fprintf('Extraction of episode %s is complete.  Amplitude range = [%d,%d]\n\n'...
    , episode.id, round(max_signal), round(min_signal) );





function hdr = read_header( fid )
% read edf header

hdr.version = fread(fid, 8,'uchar=>char')';
hdr.info1   = fread(fid,80,'uchar=>char')';
hdr.info2   = fread(fid,80,'uchar=>char')';
hdr.start_date = fread(fid,8,'uchar=>char')'; 
hdr.start_time = fread(fid,8,'uchar=>char')'; 
hdr.header_size = str2num(fread(fid,8,'uchar=>char')');
fread(fid,44);  %ignore reserved field  
hdr.nframes = str2num(fread(fid,8,'uchar=>char')');
hdr.frame_duration = str2num(fread(fid,8,'uchar=>char')');
hdr.nchannels = str2num(fread(fid,4,'uchar=>char')');
hdr.channelnames = fread(fid,[16,hdr.nchannels],'uchar=>char')';
hdr.transducer   = fread(fid,[80,hdr.nchannels],'uchar=>char')';
hdr.physdime     = fread(fid,[8 ,hdr.nchannels],'uchar=>char')';
hdr.physmin      = fread(fid,[8 ,hdr.nchannels],'uchar=>char')';
hdr.physmax      = fread(fid,[8 ,hdr.nchannels],'uchar=>char')';
hdr.digimin      = fread(fid,[8 ,hdr.nchannels],'uchar=>char')';
hdr.digimax      = fread(fid,[8 ,hdr.nchannels],'uchar=>char')';
hdr.prefilt      = fread(fid,[80,hdr.nchannels],'uchar=>char')';
hdr.samples_per_frame   = str2num(fread(fid,[8 ,hdr.nchannels],'uchar=>char')');  
fread( fid, hdr.nchannels*32 );   %ignore reserved field
assert(hdr.header_size == ftell(fid), 'Incorrect header size in EDF source file');





function write_header( fid, hdr )
% write edf header into an episode edf file

fwrite( fid, hdr.version, 'uchar' );
fwrite( fid, hdr.info1, 'uchar' );
fwrite( fid, hdr.info2, 'uchar' );
fwrite( fid, hdr.start_date, 'uchar' );
fwrite( fid, hdr.start_time, 'uchar' );
fwrite( fid, strjust(sprintf('%8d',hdr.header_size),'left'), 'uchar' );
fwrite( fid, repmat(' ',44,1), 'uchar'); %blank reserved field
fwrite( fid, strjust(sprintf('%8d',hdr.nframes),'left') , 'uchar' );
fwrite( fid, strjust(sprintf('%8f',hdr.frame_duration),'left'), 'uchar' );
fwrite( fid, strjust(sprintf('%4d',hdr.nchannels),'left' ) , 'uchar' );
fwrite( fid, hdr.channelnames', 'uchar' );
fwrite( fid, hdr.transducer', 'uchar' );
fwrite( fid, hdr.physdime', 'uchar' );
fwrite( fid, hdr.physmin', 'uchar' );
fwrite( fid, hdr.physmax', 'uchar' );
fwrite( fid, hdr.digimin', 'uchar' );
fwrite( fid, hdr.digimax', 'uchar' );
fwrite( fid, hdr.prefilt', 'uchar' );
for rate=hdr.samples_per_frame'
    fwrite( fid, strjust( sprintf('%8d',round(rate)),'left'), 'uchar' );
end
fwrite( fid, hdr.reserved', 'uchar' );
assert( ftell(fid)==hdr.header_size, 'Header_size does not match file position');





function hdr = make_episode_header( src_hdr, episode )
% create the header information for the extracted EDF file

%version is '0' regardless of source version
hdr.version = '0       ';

%remove patient information
hdr.info1 = sprintf('%80s','wiped clean');
hdr.info2 = sprintf('%80s','wiped clean');


% copy startdate -- assume extracted epoch within the same date
hdr.start_date = src_hdr.start_date;


%calculate frames to extract. 0-based time. 0-based frame numbers
hdr.start_frame = floor( episode.timerange(1) / src_hdr.frame_duration );
hdr.end_frame   = floor( episode.timerange(2) / src_hdr.frame_duration - 1/max(src_hdr.samples_per_frame) );
assert( hdr.start_frame >= 0, 'start time is less than zero' );
assert( hdr.end_frame < src_hdr.nframes, 'end time is beyond the end of the source file' ); 


% update starttime
start_second = hdr.start_frame*src_hdr.frame_duration; % round to frame start
seconds = ( str2num(src_hdr.start_time(1:2))*60 ...
          + str2num(src_hdr.start_time(4:5)))*60 ...
          + str2num(src_hdr.start_time(7:8)) ...
          + round(start_second);
        
hdr.start_time = src_hdr.start_time;
hdr.start_time(7:8) = sprintf('%02d',mod(seconds,60)); seconds = floor( seconds / 60 );
hdr.start_time(4:5) = sprintf('%02d',mod(seconds,60)); seconds = floor( seconds / 60 );
hdr.start_time(1:2) = sprintf('%02d',mod(seconds,24));


% update header_size
hdr.nchannels = length(episode.channels);
hdr.header_size = 8 + 80 + 80 + 8 + 8 + 8 + 44 + 8 + 8 + 4 ...
    + hdr.nchannels*(16 + 80 + 8 + 8 + 8 + 8 + 8 + 80 + 8 + 32 );


% update nframes and frame_duration
hdr.nframes = hdr.end_frame-hdr.start_frame+1;
hdr.frame_duration = src_hdr.frame_duration;


% update nchannels
hdr.nchannels = length( episode.channels );


% make channel names
hdr.channelnames = [];
for channel = episode.channels
    hdr.channelnames = [hdr.channelnames; strjust(sprintf('%16s',channel.name(1:min(end,80))),'left')];
end


% duplicate channel information from the first participating channel
% set digital range to [-2048 2047]
hdr.transducer = repmat( src_hdr.transducer( episode.source_channels(1), : ), hdr.nchannels, 1 );
hdr.physdime   = repmat( src_hdr.physdime  ( episode.source_channels(1), : ), hdr.nchannels, 1 );
hdr.physmin    = repmat( src_hdr.physmin   ( episode.source_channels(1), : ), hdr.nchannels, 1 );
hdr.physmax    = repmat( src_hdr.physmax   ( episode.source_channels(1), : ), hdr.nchannels, 1 );
hdr.digimin = repmat( strjust( sprintf('%8d',-2048), 'left' ), hdr.nchannels, 1);
hdr.digimax = repmat( strjust( sprintf('%8d',+2047), 'left' ) ,hdr.nchannels, 1);
hdr.prefilt    = repmat( src_hdr.prefilt   ( episode.source_channels(1), : ), hdr.nchannels, 1 );




% update samples_per_frame
rate = src_hdr.samples_per_frame(episode.source_channels);
assert( max(rate)==min(rate), 'Source channels must be sampled at the same rate' );
hdr.samples_per_frame = repmat( rate(1), hdr.nchannels, 1 );


% store the channel role and the position of sensors on the head illustration in the reserved field
hdr.reserved = [];
for channel = episode.channels
    hdr.reserved = [hdr.reserved; ...
        [channel.role ')' strjust(sprintf('%30s',num2str(round(channel.sensor_xy))), 'left')]];
end




