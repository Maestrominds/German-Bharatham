import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/job_model.dart';
import 'services/api_config.dart';

class JobsFilterPage extends StatefulWidget {
  final List<Job> allItems;
  final String? initialDomain;
  final String? initialCountry;
  final String? initialLocation;
  final int? initialJobType;
  final RangeValues? initialSalaryRange;

  const JobsFilterPage({
    super.key,
    required this.allItems,
    this.initialDomain,
    this.initialCountry,
    this.initialLocation,
    this.initialJobType,
    this.initialSalaryRange,
  });

  @override
  State<JobsFilterPage> createState() => _JobsFilterPageState();
}

class _JobsFilterPageState extends State<JobsFilterPage> {
  final TextEditingController _locationController = TextEditingController();

  // Field / Domain selection (matches profile setup)
  String _selectedDomain = 'All';
  List<String> _domainOptions = [
    'All',
    'IT / Technology',
    'Computer Science / Software',
    'Biotechnology / Life Sciences',
    'Healthcare / Medicine',
    'Finance / Banking',
    'Mechanical / Automotive',
    'Electrical / Electronics',
    'Engineering / Manufacturing',
    'Marketing / Sales',
    'Business / Management',
    'Legal / Law',
    'Education / Academia',
    'Other',
  ];

  // Country selection (clean curated list)
  String _selectedCountry = 'All Countries';
  static const List<String> _countryOptions = [
    'All Countries',
    'Germany',
    'India',
    'Europe',
    'United Kingdom',
    'United States',
    'Other / Remote',
  ];

  // Job Type: 0=All,1=Full-time,2=Part-time,3=Contract,4=Internship
  int selectedJobType = 0;

  // Salary range (in €/month)
  static const double _maxSalary = 10000;
  RangeValues _salaryRange = const RangeValues(0, _maxSalary);

  static const List<String> jobTypeLabels = [
    'All',
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
  ];

  static const List<String> jobTypeKeys = [
    '',
    'full',
    'part',
    'contract',
    'intern',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDomain != null && widget.initialDomain!.isNotEmpty) {
      _selectedDomain = widget.initialDomain!;
    }
    if (widget.initialCountry != null && widget.initialCountry!.isNotEmpty) {
      final initLower = widget.initialCountry!.trim().toLowerCase();
      final match = _countryOptions.firstWhere(
        (c) => c.toLowerCase() == initLower,
        orElse: () {
          const euOld = ['austria', 'switzerland', 'netherlands', 'poland', 'france'];
          if (euOld.contains(initLower)) return 'Europe';
          return 'All Countries';
        },
      );
      _selectedCountry = match;
    }
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _locationController.text = widget.initialLocation!;
    }
    if (widget.initialJobType != null && widget.initialJobType! >= 0 && widget.initialJobType! < jobTypeLabels.length) {
      selectedJobType = widget.initialJobType!;
    }
    if (widget.initialSalaryRange != null) {
      _salaryRange = widget.initialSalaryRange!;
    }
    _fetchDomainOptions();
  }

  Future<void> _fetchDomainOptions() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/profile-options'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        if (data['domains'] is List) {
          final list = (data['domains'] as List)
              .map((e) => e is Map ? e['name']?.toString().trim() ?? '' : e.toString().trim())
              .where((name) => name.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            setState(() {
              _domainOptions = ['All', ...list];
              // Ensure selection is valid
              if (!_domainOptions.contains(_selectedDomain)) {
                _domainOptions.add(_selectedDomain);
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Job> result = List.from(widget.allItems);

    // 1) Domain / Field filter (matches profile setup)
    if (_selectedDomain.isNotEmpty && _selectedDomain != 'All') {
      final domainLower = _selectedDomain.toLowerCase();
      final keywords = domainLower
          .split(RegExp(r'[\s/]+'))
          .map((s) => s.trim())
          .where((s) => s.length > 2)
          .toList();

      result = result.where((job) {
        final jobDomain = (job.domain ?? '').toLowerCase();
        if (jobDomain.isNotEmpty) {
          if (jobDomain.contains(domainLower) || domainLower.contains(jobDomain)) return true;
          for (final kw in keywords) {
            if (jobDomain.contains(kw)) return true;
          }
        }
        for (final kw in keywords) {
          if (job.title.toLowerCase().contains(kw) ||
              (job.description ?? '').toLowerCase().contains(kw) ||
              job.category.toLowerCase().contains(kw)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // 2) Country filter
    if (_selectedCountry.isNotEmpty && _selectedCountry != 'All Countries') {
      final cLower = _selectedCountry.toLowerCase();
      result = result.where((job) {
        final jobCountry = job.country.toLowerCase();
        final jobLocation = job.location.toLowerCase();
        if (cLower.contains('remote') || cLower.contains('other')) {
          return jobCountry.contains('remote') ||
              jobCountry.contains('other') ||
              jobLocation.contains('remote');
        }
        if (cLower == 'europe') {
          const euKeywords = [
            'europe',
            'eu',
            'austria',
            'switzerland',
            'netherlands',
            'poland',
            'france',
            'spain',
            'italy',
            'ireland',
            'belgium',
            'sweden',
            'norway',
            'denmark',
            'finland',
            'portugal',
          ];
          return euKeywords.any((kw) => jobCountry.contains(kw) || jobLocation.contains(kw));
        }
        return jobCountry.contains(cLower) || jobLocation.contains(cLower);
      }).toList();
    }

    // 3) Location filter (City / Area)
    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      result = result.where((job) {
        return job.city.toLowerCase().contains(locationQuery) ||
            job.location.toLowerCase().contains(locationQuery) ||
            job.title.toLowerCase().contains(locationQuery) ||
            job.company.toLowerCase().contains(locationQuery);
      }).toList();
    }

    // 4) Job type filter
    if (selectedJobType != 0) {
      final key = jobTypeKeys[selectedJobType];
      result = result.where((job) {
        return job.jobType.toLowerCase().contains(key);
      }).toList();
    }

    // 5) Salary range filter
    if (_salaryRange.start > 0 || _salaryRange.end < _maxSalary) {
      result = result.where((job) {
        if (job.salary == null || job.salary!.isEmpty) return true;
        final match = RegExp(r'\d+').firstMatch(job.salary!.replaceAll(',', '').replaceAll('.', ''));
        if (match == null) return true;
        final amount = double.tryParse(match.group(0) ?? '0') ?? 0;
        return amount >= _salaryRange.start && amount <= _salaryRange.end;
      }).toList();
    }

    Navigator.pop(context, {
      'filtered': result,
      'selectedDomain': _selectedDomain,
      'selectedCountry': _selectedCountry,
      'selectedLocation': _locationController.text.trim(),
      'selectedJobType': selectedJobType,
      'selectedSalaryRange': _salaryRange,
    });
  }

  void _resetFilters() {
    setState(() {
      _locationController.clear();
      _selectedDomain = 'All';
      _selectedCountry = 'All Countries';
      selectedJobType = 0;
      _salaryRange = const RangeValues(0, _maxSalary);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Filters',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/images/left-arrow.png',
            height: 22,
            width: 22,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFF4E7F6D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Field / Domain Dropdown ──────────────────────────────
            Row(
              children: [
                const Icon(Icons.category_rounded, size: 18, color: Color(0xFF4E7F6D)),
                const SizedBox(width: 6),
                const Text(
                  'Field / Domain',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Synchronized with profile setup domains',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _domainOptions.contains(_selectedDomain) ? _selectedDomain : 'All',
                // Displays ~4 values at a time with scroll so it doesn't take over half the screen!
                menuMaxHeight: 200,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF4E7F6D), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _domainOptions.map((domain) {
                  return DropdownMenuItem<String>(
                    value: domain,
                    child: Text(
                      domain,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDomain = val);
                  }
                },
              ),
            ),

            const SizedBox(height: 22),

            // ── 2. Country Dropdown ─────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.public, size: 18, color: Color(0xFF4E7F6D)),
                const SizedBox(width: 6),
                const Text(
                  'Country',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Filter jobs by country',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCountry,
                // Displays ~4 values at a time with scroll so it doesn't take over half the screen!
                menuMaxHeight: 200,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF4E7F6D), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _countryOptions.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(
                      country,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCountry = val);
                  }
                },
              ),
            ),

            const SizedBox(height: 22),

            // ── 3. City / Location ──────────────────────────────────────
            Row(
              children: [
                Image.asset(
                  'assets/images/location.png',
                  height: 18,
                  width: 18,
                  color: const Color(0xFF4E7F6D),
                  errorBuilder: (_, __, ___) => const SizedBox(width: 18, height: 18),
                ),
                const SizedBox(width: 6),
                const Text(
                  'City / Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter city or area (e.g. Berlin, Munich)',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/location.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFF4E7F6D),
                    errorBuilder: (_, __, ___) => const Icon(Icons.location_on, color: Color(0xFF4E7F6D)),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ── 4. Job Type ─────────────────────────────────────────────
            Row(
              children: [
                Image.asset(
                  'assets/images/job-search.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4E7F6D),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Job Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(jobTypeLabels.length, (index) {
                final isSelected = selectedJobType == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedJobType = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4E7F6D) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      jobTypeLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 26),

            // ── 5. Salary Range ─────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.euro, size: 16, color: Color(0xFF4E7F6D)),
                const SizedBox(width: 6),
                const Text(
                  'Salary Range (€/month)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '€${_salaryRange.start.toInt()}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4E7F6D), fontWeight: FontWeight.w600),
                ),
                Text(
                  _salaryRange.end >= _maxSalary
                      ? '€${_salaryRange.end.toInt()}+'
                      : '€${_salaryRange.end.toInt()}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4E7F6D), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF4E7F6D),
                inactiveTrackColor: const Color(0xFFD1E8DF),
                thumbColor: const Color(0xFF4E7F6D),
                overlayColor: const Color(0xFF4E7F6D).withOpacity(0.15),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: RangeSlider(
                values: _salaryRange,
                min: 0,
                max: _maxSalary,
                divisions: 20,
                onChanged: (v) => setState(() => _salaryRange = v),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E7F6D),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _applyFilters,
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
