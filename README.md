# icaching-nuvi - Icaching geocaching data preprocessor for Garmin POI Loader

## Introduction

This script reads an [Icaching](http://icaching.eu) database and generates a
GPX file suitable for passing to 
[Garmin POI Loader](http://www8.garmin.com/products/poiloader/) to load onto a Garmin n&uuml;vi
GPS.

We can visualize the flow of geocaching data like so:

    geocaching.com pocket queries -> Icaching -> icaching-nuvi -> POI Loader -> nüvi GPS

icaching-nuvi is based on my older project for GSAK, [nuvigc](https://github.com/mortonfox/nuvigc), which is itself based on a GSAK macro at
[Garmin N&uuml;vi - True Paperless Geocaching](http://geocaching.williamsonnetwork.com).

Note that Icaching itself offers a GPX export feature. The difference is icaching-nuvi adds a lot more geocache information to the name and description fields, so you can read that on the n&uuml;vi.

## Setup

## Usage

## Caution

Avoid using numbers in Icaching folder names. POI Loader will convert waypoints
from those folders to speed alerts instead of regular POIs and you will not be
able to route to them.

