import 'package:flutter/material.dart';
import 'models/job_model.dart';

class JobsFilterPage extends StatefulWidget {
  final List<Job> allItems;

  const JobsFilterPage({super.key, required this.allItems});

  @override
  State<JobsFilterPage> createState() => _JobsFilterPageState();
}

class _JobsFilterPageState extends State<JobsFilterPage> {
  final TextEditingController _locationController = TextEditingController();

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
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Job> result = List.from(widget.allItems);

    // 1) Location filter
    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      result = result.where((job) {
        return job.city.toLowerCase().contains(locationQuery) ||
            job.location.toLowerCase().contains(locationQuery) ||
            job.title.toLowerCase().contains(locationQuery) ||
            job.company.toLowerCase().contains(locationQuery);
      }).toList();
    }

    // 2) Job type filter
    if (selectedJobType != 0) {
      final key = jobTypeKeys[selectedJobType];
      result = result.where((job) {
        return job.jobType.toLowerCase().contains(key);
      }).toList();
    }

    // 3) Salary range filter (extract first number from salary string)
    if (_salaryRange.start > 0 || _salaryRange.end < _maxSalary) {
      result = result.where((job) {
        if (job.salary == null || job.salary!.isEmpty) return true;
        final match = RegExp(r'\d+').firstMatch(job.salary!.replaceAll(',', '').replaceAll('.', ''));
        if (match == null) return true;
        final amount = double.tryParse(match.group(0) ?? '0') ?? 0;
        return amount >= _salaryRange.start && amount <= _salaryRange.end;
      }).toList();
    }

    Navigator.pop(context, result);
  }

  void _resetFilters() {
    setState(() {
      _locationController.clear();
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
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter city or area',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/location.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFF4E7F6D),
                    errorBuilder: (_, __, ___) => const SizedBox(width: 18, height: 18),
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
            const SizedBox(height: 28),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4E7F6D)
                          : const Color(0xFFE5E7EB),
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
            const SizedBox(height: 28),
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
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E7F6D),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
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
          ],
        ),
      ),
    );
  }
}
