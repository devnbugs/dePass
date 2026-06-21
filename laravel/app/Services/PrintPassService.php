<?php

namespace App\Services;

use App\Models\Event;
use App\Models\PassTemplate;

class PrintPassService
{
    public function buildPrintManifest(Event $event, array $passes, ?PassTemplate $template = null): array
    {
        $templateDetails = null;

        if ($template) {
            $templateDetails = [
                'id' => $template->id,
                'name' => $template->name,
                'url' => $template->url,
                'content_type' => $template->content_type,
                'layout' => $template->layout,
            ];
        }

        return [
            'event' => [
                'id' => $event->id,
                'name' => $event->name,
                'date' => $event->date?->toIso8601String(),
                'location' => $event->location,
            ],
            'template' => $templateDetails,
            'layout' => $template?->layout ?? $this->defaultLayout(),
            'cards' => array_map(function ($pass, $index) {
                return [
                    'index' => $index + 1,
                    'pass_id' => $pass->id,
                    'pass_uid' => $pass->pass_uid,
                    'attendee_name' => $pass->attendee_name,
                    'company' => $pass->company,
                    'phone' => $pass->phone,
                    'status' => $pass->status,
                    'qr_data' => sprintf('GPX1|%s|%s', $pass->pass_uid, $pass->signature),
                ];
            }, $passes, array_keys($passes)),
        ];
    }

    protected function defaultLayout(): array
    {
        return [
            'page_format' => 'A4',
            'orientation' => 'portrait',
            'page_margin_mm' => 12,
            'grid' => [
                'columns' => 2,
                'rows' => 5,
                'gutter_mm' => 8,
            ],
            'card' => [
                'width_mm' => 90,
                'height_mm' => 54,
                'qr_zone' => [
                    'x' => 60,
                    'y' => 12,
                    'width' => 24,
                    'height' => 24,
                ],
                'text_zone' => [
                    'x' => 12,
                    'y' => 12,
                    'width' => 44,
                    'height' => 30,
                ],
            ],
        ];
    }
}
