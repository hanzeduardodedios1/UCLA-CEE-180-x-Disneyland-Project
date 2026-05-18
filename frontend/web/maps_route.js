// Google Maps JavaScript API — display walking route (polyline from backend or Directions).
(function () {
  const loaders = {};

  function loadGoogleMaps(apiKey) {
    if (window.google && window.google.maps && window.google.maps.geometry) {
      return Promise.resolve();
    }
    if (loaders[apiKey]) {
      return loaders[apiKey];
    }
    loaders[apiKey] = new Promise(function (resolve, reject) {
      const script = document.createElement('script');
      script.src =
        'https://maps.googleapis.com/maps/api/js?key=' +
        encodeURIComponent(apiKey) +
        '&libraries=geometry';
      script.async = true;
      script.defer = true;
      script.onload = function () {
        resolve();
      };
      script.onerror = function () {
        reject(new Error('Failed to load Google Maps JavaScript API'));
      };
      document.head.appendChild(script);
    });
    return loaders[apiKey];
  }

  function showMessage(container, text, isError) {
    container.innerHTML = '';
    const msg = document.createElement('p');
    msg.textContent = text;
    msg.style.margin = '0';
    msg.style.padding = '16px';
    msg.style.fontSize = '13px';
    msg.style.lineHeight = '1.4';
    msg.style.color = isError ? '#b91c1c' : '#6b7280';
    msg.style.textAlign = 'center';
    container.appendChild(msg);
  }

  function renderPolylineRoute(container, apiKey, polyline, origin, destination) {
    loadGoogleMaps(apiKey)
      .then(function () {
        container.innerHTML = '';
        const mapEl = document.createElement(String.fromCharCode(100, 105, 118));
        mapEl.style.width = '100%';
        mapEl.style.height = '100%';
        mapEl.style.minHeight = '240px';
        container.appendChild(mapEl);

        const path = google.maps.geometry.encoding.decodePath(polyline);
        if (!path.length) {
          showMessage(container, 'Could not decode route path.', true);
          return;
        }

        const map = new google.maps.Map(mapEl, {
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: true,
        });

        new google.maps.Polyline({
          path: path,
          map: map,
          strokeColor: '#7c3aed',
          strokeWeight: 5,
          strokeOpacity: 0.95,
        });

        new google.maps.Marker({
          map: map,
          position: path[0],
          title: origin || 'Hotel',
          label: 'A',
        });

        new google.maps.Marker({
          map: map,
          position: path[path.length - 1],
          title: destination || 'Disneyland',
          label: 'B',
        });

        const bounds = new google.maps.LatLngBounds();
        path.forEach(function (point) {
          bounds.extend(point);
        });
        map.fitBounds(bounds, { top: 40, right: 40, bottom: 40, left: 40 });
      })
      .catch(function (err) {
        showMessage(
          container,
          err && err.message ? err.message : 'Failed to load map.',
          true
        );
      });
  }

  function renderDirectionsRoute(container, apiKey, origin, destination, travelMode) {
    loadGoogleMaps(apiKey)
      .then(function () {
        container.innerHTML = '';
        const mapEl = document.createElement(String.fromCharCode(100, 105, 118));
        mapEl.style.width = '100%';
        mapEl.style.height = '100%';
        mapEl.style.minHeight = '240px';
        container.appendChild(mapEl);

        const map = new google.maps.Map(mapEl, {
          zoom: 14,
          center: { lat: 33.8121, lng: -117.919 },
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: true,
        });

        const directionsService = new google.maps.DirectionsService();
        const directionsRenderer = new google.maps.DirectionsRenderer({
          map: map,
          suppressMarkers: false,
          polylineOptions: {
            strokeColor: '#7c3aed',
            strokeWeight: 5,
          },
        });

        directionsService.route(
          {
            origin: origin,
            destination: destination,
            travelMode:
              google.maps.TravelMode[travelMode] || google.maps.TravelMode.WALKING,
          },
          function (result, status) {
            if (status === google.maps.DirectionsStatus.OK) {
              directionsRenderer.setDirections(result);
              return;
            }
            const detail =
              status === 'ZERO_RESULTS'
                ? 'No walking route found for this address.'
                : 'Could not load route (' + status + ').';
            showMessage(container, detail, true);
          }
        );
      })
      .catch(function (err) {
        showMessage(
          container,
          err && err.message ? err.message : 'Failed to load Google Maps.',
          true
        );
      });
  }

  /**
   * @param {HTMLElement} container
   * @param {{ apiKey: string, origin?: string, destination?: string, travelMode?: string, polyline?: string }} options
   */
  window.renderHotelRouteMap = function (container, options) {
    const apiKey = options.apiKey || '';
    const origin = options.origin || '';
    const destination = options.destination || '';
    const travelMode = options.travelMode || 'WALKING';
    const polyline = options.polyline || '';

    container.style.position = 'relative';
    container.style.overflow = 'hidden';
    container.style.background = '#e5e7eb';
    container.style.minHeight = '240px';

    if (!apiKey || apiKey === 'your_google_maps_js_api_key_here') {
      showMessage(
        container,
        'Add GOOGLE_MAPS_JS_API_KEY to .env and pass it with --dart-define=GOOGLE_MAPS_JS_API_KEY=...',
        true
      );
      return;
    }

    showMessage(container, 'Loading map…', false);

    if (polyline) {
      renderPolylineRoute(container, apiKey, polyline, origin, destination);
      return;
    }

    if (!origin || !destination) {
      showMessage(container, 'Hotel address unavailable for routing.', true);
      return;
    }

    renderDirectionsRoute(container, apiKey, origin, destination, travelMode);
  };
})();
