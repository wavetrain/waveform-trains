function make_trains_C( signal_filename, train_filename, epoch, step, ntrains, widths )

disp('Calling C implemention of make_trains');
cmd = sprintf('./make_trains %s %s %d %d %d ', signal_filename, train_filename, epoch, step, ntrains );
cmd = [cmd num2str(widths)];
system(cmd);