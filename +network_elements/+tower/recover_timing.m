function timing_correction = recover_timing(input_stream)
% Schmidl Cox Algorithm

if 1
    search_offset       = 7+75*[1 2 3 4 5]; % where to start looking
    time_offset         = 32;
    window_length       = 31;
    search_length       = 15;
    aim_correction      = 75*[0 1 2 3 4]; % empirically found
else
    search_offset = 65;
    window_length = 83;
    time_offset = 76;
    search_length = 20;
    aim_correction = 69;
end

% Do Schmidl-Cox on all Sync symbols, then agree on mean estimation
for jj = 1:length(search_offset)
    for ii = search_offset(jj):search_offset(jj)+search_length
        
        ind_off     = ii+time_offset;
        P(ii, jj)   = input_stream(ind_off:ind_off+window_length)*...
            input_stream(ii:ii+window_length)';
        R(ii, jj)   = input_stream(ind_off:ind_off+window_length)*...
            input_stream(ind_off:ind_off+window_length)';
        
        M(ii, jj)   = abs(P(ii, jj))^2 / R(ii, jj)^2;
        
    end
    [max_val(jj), max_ind(jj)] = max(M(:, jj));
end
offset_corrected_ind =max_ind(2:4)-aim_correction(2:4);
 W = sum(M.^2, 1);
 W_norm = W(2:4)/sum(W(2:4));
timing_correction =round(offset_corrected_ind*W_norm')-86;
end