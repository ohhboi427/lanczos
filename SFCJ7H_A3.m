function dest = lanczos_resize(img, scale, angle)
    [src_h, src_w, num_channels] = size(img);
    dest_w = src_w * scale;
    dest_h = src_h * scale;

    function y = sinc(x)
        if x == 0
            y = 1;
        else
            y = sin(pi * x) / (pi * x);
        end
    end

    function w = lanczos_kernel(x, a)
        if abs(x) >= a
            w = 0;
        else
            w = sinc(x) * sinc(x / a);
        end
    end

    A = 3; % Kernel size parameter

    rotation_matrix = [cosd(angle), -sind(angle); sind(angle), cosd(angle)];

    dest = uint8(zeros(dest_h, dest_w, num_channels));

    scale_x = src_w / dest_w;
    scale_y = src_h / dest_h;

    for v = 1:dest_h
        for u = 1:dest_w
            scaled_x = (u - 1) * scale_x + 1;
            scaled_y = (v - 1) * scale_y + 1;

            rotated_coords = rotation_matrix \ [(scaled_x - src_w / 2); (scaled_y - src_h / 2)];
            src_x = rotated_coords(1) + src_w / 2;
            src_y = rotated_coords(2) + src_h / 2;

            pixel_sum = zeros(1, num_channels);
            weight_sum = 0;

            for dy = floor(src_y) - A + 1 : floor(src_y) + A
                for dx = floor(src_x) - A + 1 : floor(src_x) + A
                    if dy < 1 || dy > src_h || dx < 1 || dx > src_w
                        continue;
                    end
                    
                    w = lanczos_kernel(src_x - dx, A) * lanczos_kernel(src_y - dy, A);

                    for c = 1:num_channels
                        pixel_sum(c) = pixel_sum(c) + double(img(dy, dx, c)) * w;
                    end

                    weight_sum = weight_sum + w;
                end
            end

            for c = 1:num_channels
                p = pixel_sum(c) / weight_sum;
                p = max(0, min(255, p));
                dest(v, u, c) = uint8(p);
            end
        end
    end
end

function test_case(scale, angle)
    img = imread('lena.png');

    output = lanczos_resize(img, scale, angle);

    figure;
    imshow(output);
    title(sprintf('Resized and Rotated image to %.02f with %d degrees', scale, angle));
    % imwrite(output, sprintf('lena_%.02f@%.02f.png', scale, angle));
end

test_case(4, 0)
test_case(2, 45)
test_case(0.5, 90)
