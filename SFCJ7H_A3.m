function dest = lanczos_resize(img, scale, angle)
    [src_h, src_w, num_channels] = size(img);

    scaled_w = src_w * scale;
    scaled_h = src_h * scale;

    corners = [
        -scaled_w / 2, -scaled_h / 2;
         scaled_w / 2, -scaled_h / 2;
         scaled_w / 2,  scaled_h / 2;
        -scaled_w / 2,  scaled_h / 2
    ];

    rotation_matrix = [cosd(angle), -sind(angle); sind(angle), cosd(angle)];

    rotated_corners = (rotation_matrix * corners')';
    min_x = min(rotated_corners(:, 1));
    max_x = max(rotated_corners(:, 1));
    min_y = min(rotated_corners(:, 2));
    max_y = max(rotated_corners(:, 2));

    dest_w = ceil(max_x - min_x);
    dest_h = ceil(max_y - min_y);

    dest = uint8(zeros(dest_h, dest_w, num_channels));

    scale_x = src_w / scaled_w;
    scale_y = src_h / scaled_h;

    center_x = dest_w / 2;
    center_y = dest_h / 2;

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

    for v = 1:dest_h
        for u = 1:dest_w
            dx = (u - center_x);
            dy = (v - center_y);

            rotated_coords = rotation_matrix \ [dx; dy];
            scaled_x = rotated_coords(1);
            scaled_y = rotated_coords(2);

            src_x = scaled_x * scale_x + src_w / 2;
            src_y = scaled_y * scale_y + src_h / 2;

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
    title(sprintf('Resized (%.2f) and Rotated (%d°) Image', scale, angle));
    % imwrite(output, sprintf('lena_%.02f@%.02f.png', scale, angle));
end

test_case(4, 0);
test_case(2, 45);
test_case(0.5, 90);
