class TrafficUnitConstants {
  static const Map<String, List<String>> STATION_MAPPING = {
    'thanenagartrafficunit': ['THANENAGAR POLICE STATION'],
    'raboditrafficunit': ['THANENAGAR POLICE STATION', 'RABODI POLICE STATION'],
    'naupadatrafficunit': ['NAUPADA POLICE STATION', 'KOPARI POLICE STATION'],
    'kalwatrafficunit': ['KALWA POLICE STATION'],
    'mumbratrafficunit': ['MUMBRA POLICE STATION', 'SHILDOIGHAR POLICE STATION'],
    'wagaletrafficunit': ['WAGALE ESTATE POLICE STATION', 'SHRINAGAR POLICE STATION', 'VARTAKNAGAR POLICE STATION'],
    'kapurbawaditrafficunit': ['KAPURBAWADI POLICE STATION', 'CHITALSAR POLICE STATION', 'VARTAKNAGAR POLICE STATION', 'RABODI POLICE STATION'],
    'wadavalitrafficunit': ['WADAVALI POLICE STATION', 'KASARWADAWALI POLICE STATION', 'TOWN POLICE STATION', 'SHANTINAGAR POLICE STATION', 'NIZAMPURA POLICE STATION', 'BHOIWADA POLICE STATION'],
    'narpolitrafficunit': ['BHOIWADA POLICE STATION', 'NARPOLI POLICE STATION'],
    'kongaontrafficunit': ['SHANTINAGAR POLICE STATION', 'KONGAON POLICE STATION'],
    'kalyantrafficunit': ['MAHATMA PHULE CHOUK POLICE STATION', 'KHADAKPADA POLICE STATION', 'BAZARPETH POLICE STATION'],
    'dombivalitrafficunit': ['TILAKNAGAR POLICE STATION', 'DOMBIWALI POLICE STATION', 'VISHNUNAGAR POLICE STATION'],
    'kolsewaditrafficunit': ['KOLSHEWADI POLICE STATION'],
    'ulhasnagartrafficunit': ['ULHASNAGAR POLICE STATION', 'CETRAL POLICE STATION'],
    'ambarnathtrafficunit': ['AMBARNATH POLICE STATION', 'SHIVAJINAGAR POLICE STATION', 'BADALAPUR EAST POLICE STATION'],
    'vitthalwaditrafficunit': ['HILLLINE POLICE STATION', 'VITTHALWADI POLICE STATION'],
    'bhiwanditrafficunit': ['BHIWANDI POLICE STATION']
  };

  static const Map<String, String> TRAFFIC_UNIT_DISPLAY_NAMES = {
    'thanenagartrafficunit': 'Thane Nagar Traffic Unit',
    'raboditrafficunit': 'Rabodi Traffic Unit',
    'naupadatrafficunit': 'Naupada Traffic Unit',
    'kalwatrafficunit': 'Kalwa Traffic Unit',
    'mumbratrafficunit': 'Mumbra Traffic Unit',
    'wagaletrafficunit': 'Wagale Traffic Unit',
    'kapurbawaditrafficunit': 'Kapurbawadi Traffic Unit',
    'wadavalitrafficunit': 'Wadavali Traffic Unit',
    'narpolitrafficunit': 'Narpoli Traffic Unit',
    'kongaontrafficunit': 'Kongaon Traffic Unit',
    'kalyantrafficunit': 'Kalyan Traffic Unit',
    'dombivalitrafficunit': 'Dombivali Traffic Unit',
    'kolsewaditrafficunit': 'Kolshewadi Traffic Unit',
    'ulhasnagartrafficunit': 'Ulhasnagar Traffic Unit',
    'ambarnathtrafficunit': 'Ambarnath Traffic Unit',
    'vitthalwaditrafficunit': 'Vitthalwadi Traffic Unit',
    'bhiwanditrafficunit': 'Bhiwandi Traffic Unit'
  };

  static List<String> getTrafficUnitsForPoliceStation(String policeStation) {
    List<String> availableUnits = [];

    STATION_MAPPING.forEach((unitKey, policeStations) {
      if (policeStations.contains(policeStation)) {
        availableUnits.add(unitKey);
      }
    });

    return availableUnits;
  }

  static String getTrafficUnitDisplayName(String unitKey) {
    return TRAFFIC_UNIT_DISPLAY_NAMES[unitKey] ?? unitKey;
  }
}