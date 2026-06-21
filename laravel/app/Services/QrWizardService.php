<?php

namespace App\Services;

use App\Models\SystemConfiguration;
use chillerlan\QRCode\Output\QRGdImagePNG;
use chillerlan\QRCode\QRCode;
use chillerlan\QRCode\QROptions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QrWizardService
{
    private const COUNTER_KEY = 'qr_wizard_serial_counter';

    public function __construct(
        private readonly QrSignatureService $signatureService,
    ) {}

    public function getThemes(): array
    {
        return [
            [
                'id' => 'classic',
                'name' => 'Classic',
                'description' => 'Black on white — standard QR',
                'colors' => ['#000000', '#FFFFFF'],
            ],
            [
                'id' => 'neon',
                'name' => 'Neon',
                'description' => 'Cyan on dark — modern glow',
                'colors' => ['#00E5FF', '#1A1A2E'],
            ],
            [
                'id' => 'gold',
                'name' => 'Gold',
                'description' => 'Gold on black — premium look',
                'colors' => ['#FFD700', '#000000'],
            ],
            [
                'id' => 'ocean',
                'name' => 'Ocean',
                'description' => 'Blue on white — clean & calm',
                'colors' => ['#1565C0', '#FFFFFF'],
            ],
        ];
    }

    public function generateGpid(?int $serial = null, string $prefix = 'GPX'): string
    {
        if ($serial === null) {
            $serial = $this->getNextSerial();
        }

        return sprintf('%s-%06d', $prefix, $serial);
    }

    public function getNextSerial(): int
    {
        return DB::transaction(function () {
            $config = SystemConfiguration::firstOrCreate(
                ['key' => self::COUNTER_KEY],
                ['value' => 0, 'description' => 'QR Wizard serial number counter'],
            );

            $current = (int) (is_array($config->value) ? ($config->value['serial'] ?? 0) : $config->value);
            $next = $current + 1;

            $config->update(['value' => $next]);

            return $next;
        });
    }

    public function getCurrentSerial(): int
    {
        $config = SystemConfiguration::where('key', self::COUNTER_KEY)->first();
        if (! $config) {
            return 0;
        }

        return (int) (is_array($config->value) ? ($config->value['serial'] ?? 0) : $config->value);
    }

    public function generateQrData(string $gpid, string $eventSecret): array
    {
        $signature = $this->signatureService->generateSignature($gpid, $eventSecret);
        $qrString = sprintf('GPX1|%s|%s', $gpid, $signature);

        return [
            'qr_data' => $qrString,
            'signature' => $signature,
        ];
    }

    public function generateQrImage(string $qrData, string $theme = 'classic'): string
    {
        $themes = collect($this->getThemes())->keyBy('id');
        $themeConfig = $themes->get($theme, $themes->get('classic'));

        $darkColor = $themeConfig['colors'][0];
        $lightColor = $themeConfig['colors'][1];

        $darkHex = ltrim($darkColor, '#');
        $lightHex = ltrim($lightColor, '#');

        $options = new QROptions;
        $options->addQuietzone = true;
        $options->quietzoneSize = 2;
        $options->outputBase64 = true;
        $options->imageTransparent = false;
        $options->scale = 10;
        $options->outputInterface = QRGdImagePNG::class;

        $qrcode = new QRCode($options);
        $pngData = $qrcode->render($qrData);

        if (str_starts_with($pngData, 'data:image/')) {
            $pngData = substr($pngData, strpos($pngData, ',') + 1);
        }

        $pngBinary = base64_decode($pngData);

        $image = imagecreatefromstring($pngBinary);
        if ($image === false) {
            return $pngData;
        }

        $width = imagesx($image);
        $height = imagesy($image);

        $darkR = hexdec(substr($darkHex, 0, 2));
        $darkG = hexdec(substr($darkHex, 2, 2));
        $darkB = hexdec(substr($darkHex, 4, 2));
        $lightR = hexdec(substr($lightHex, 0, 2));
        $lightG = hexdec(substr($lightHex, 2, 2));
        $lightB = hexdec(substr($lightHex, 4, 2));

        $darkColorAlloc = imagecolorallocate($image, $darkR, $darkG, $darkB);
        $lightColorAlloc = imagecolorallocate($image, $lightR, $lightG, $lightB);

        for ($y = 0; $y < $height; $y++) {
            for ($x = 0; $x < $width; $x++) {
                $index = imagecolorat($image, $x, $y);
                $rgba = imagecolorsforindex($image, $index);
                if ($rgba['red'] < 128 && $rgba['green'] < 128 && $rgba['blue'] < 128) {
                    imagesetpixel($image, $x, $y, $darkColorAlloc);
                } else {
                    imagesetpixel($image, $x, $y, $lightColorAlloc);
                }
            }
        }

        ob_start();
        imagepng($image);
        $coloredPng = ob_get_clean();
        imagedestroy($image);

        return 'data:image/png;base64,'.base64_encode($coloredPng);
    }

    public function buildZip(array $entries, string $prefix = 'qrs'): string
    {
        $zip = new \ZipArchive;
        $tmpFile = tempnam(sys_get_temp_dir(), 'qr_').'.zip';

        if ($zip->open($tmpFile, \ZipArchive::CREATE) !== true) {
            throw new \RuntimeException('Failed to create ZIP archive');
        }

        $manifest = [];

        foreach ($entries as $i => $entry) {
            $filename = sprintf('%s_%s.png', $prefix, $entry['gpid']);
            $qb64 = $entry['qr_image_base64'];

            if (str_starts_with($qb64, 'data:image/png;base64,')) {
                $qb64 = substr($qb64, 22);
            }

            $pngBinary = base64_decode($qb64);
            if ($pngBinary === false) {
                continue;
            }

            $zip->addFromString($filename, $pngBinary);

            $manifest[] = [
                'file' => $filename,
                'gpid' => $entry['gpid'],
                'name' => $entry['name'] ?? '',
                'phone' => $entry['phone'] ?? '',
                'theme' => $entry['theme'] ?? 'classic',
                'qr_data' => $entry['qr_data'] ?? '',
            ];
        }

        $zip->addFromString('manifest.json', json_encode($manifest, JSON_PRETTY_PRINT));
        $zip->close();

        return $tmpFile;
    }

    public function generateRandomPassUid(int $length = 16): string
    {
        return Str::upper(Str::random($length));
    }
}
