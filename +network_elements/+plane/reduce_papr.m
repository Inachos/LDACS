function [ output_stream ] = reduce_papr( input_stream, papr_position)
    symbol_alph = [0 1 1j -1 -1j];
    frame = zeros(64, length(symbol_alph));
    frame(papr_position+33, :) = symbol_alph;
    time_papr = sqrt(64)*ifft(frame,64).';
    candidates = repmat(input_stream, length(symbol_alph), 1)+time_papr;
    papr = get_papr(candidates);
    [min_papr, ind] = min(papr);
    output_stream = candidates(ind, :);

end

function [papr] = get_papr(input_stream)
    average_power = sum(abs(input_stream).^2, 2)/size(input_stream, 2);
    peak_power = max(abs(input_stream).^2,[], 2);
    papr = 10*log10(peak_power./average_power);
end