function assert_( condition, msg )
% soft assert: only a warning is generated
if ~condition
    warning( msg );
end 