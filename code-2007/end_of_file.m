function ret = end_of_file( fid )
% for some reason MATLAB's feof() fails to detect the end of file until
% after an attempt is made to read past the end of the file
pos1 = ftell(fid);
fseek(fid,0,'eof');
pos2 = ftell(fid);
ret = pos1 == pos2;
fseek(fid,pos1,'bof');
