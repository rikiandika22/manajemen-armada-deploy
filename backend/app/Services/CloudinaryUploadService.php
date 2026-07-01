<?php

namespace App\Services;

use Cloudinary\Cloudinary;
use Cloudinary\Configuration\Configuration;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;

class CloudinaryUploadService
{
    protected $cloudinary;

    public function __construct()
    {
        $cloudinaryUrl = env('CLOUDINARY_URL');
        if ($cloudinaryUrl) {
            Configuration::instance($cloudinaryUrl);
            $this->cloudinary = new Cloudinary(Configuration::instance());
        } else {
            // Fallback for missing URL if it's set manually
            $this->cloudinary = new Cloudinary([
                'cloud' => [
                    'cloud_name' => env('CLOUDINARY_CLOUD_NAME'),
                    'api_key'    => env('CLOUDINARY_API_KEY'),
                    'api_secret' => env('CLOUDINARY_API_SECRET'),
                ],
                'url' => [
                    'secure' => true,
                ]
            ]);
        }
    }

    /**
     * Upload an image to Cloudinary.
     *
     * @param UploadedFile $file
     * @param string $folder
     * @return array|null Returns array with secure_url, public_id, format, resource_type or null on failure.
     */
    public function uploadImage(UploadedFile $file, string $folder): ?array
    {
        try {
            $response = $this->cloudinary->uploadApi()->upload($file->getRealPath(), [
                'folder' => $folder,
                'resource_type' => 'auto' // Handle both images and potentially PDFs
            ]);

            return [
                'secure_url' => $response['secure_url'],
                'public_id' => $response['public_id'],
                'format' => $response['format'] ?? null,
                'resource_type' => $response['resource_type'] ?? null,
            ];
        } catch (\Exception $e) {
            Log::error('Cloudinary Upload Error: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Delete an asset from Cloudinary by its public ID.
     *
     * @param string|null $publicId
     * @return bool
     */
    public function deleteByPublicId(?string $publicId): bool
    {
        if (!$publicId) {
            return false;
        }

        try {
            $response = $this->cloudinary->uploadApi()->destroy($publicId);
            return $response['result'] === 'ok';
        } catch (\Exception $e) {
            Log::warning('Cloudinary Delete Error: ' . $e->getMessage());
            return false;
        }
    }
}
