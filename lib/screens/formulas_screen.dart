import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';

const _formulas = {
  '⚡ Electricity': [
    {'name': "Ohm's Law", 'formula': 'V = IR', 'desc': 'Voltage = Current × Resistance'},
    {'name': 'Power', 'formula': 'P = VI = I²R = V²/R', 'desc': 'Electrical power'},
    {'name': 'Capacitance', 'formula': 'Q = CV', 'desc': 'Charge = Capacitance × Voltage'},
    {'name': 'Electric Field', 'formula': 'E = F/q = V/d', 'desc': 'Electric field strength'},
    {'name': 'Resistors in Series', 'formula': 'R_total = R₁ + R₂ + R₃', 'desc': 'Total resistance in series'},
    {'name': 'Resistors in Parallel', 'formula': '1/R = 1/R₁ + 1/R₂', 'desc': 'Total resistance in parallel'},
  ],
  '🚀 Motion': [
    {'name': 'Velocity', 'formula': 'v = u + at', 'desc': 'Final velocity with acceleration'},
    {'name': 'Displacement', 'formula': 's = ut + ½at²', 'desc': 'Distance traveled'},
    {'name': 'Velocity²', 'formula': 'v² = u² + 2as', 'desc': 'Velocity-displacement relation'},
    {'name': "Newton's 2nd Law", 'formula': 'F = ma', 'desc': 'Force = mass × acceleration'},
    {'name': 'Momentum', 'formula': 'p = mv', 'desc': 'Momentum = mass × velocity'},
    {'name': 'Centripetal Force', 'formula': 'F = mv²/r', 'desc': 'Force toward center of circle'},
  ],
  '💡 Energy': [
    {'name': 'Kinetic Energy', 'formula': 'KE = ½mv²', 'desc': 'Energy of motion'},
    {'name': 'Potential Energy', 'formula': 'PE = mgh', 'desc': 'Gravitational potential energy'},
    {'name': 'Work', 'formula': 'W = Fd·cosθ', 'desc': 'Work done by a force'},
    {'name': 'Power', 'formula': 'P = W/t = Fv', 'desc': 'Rate of doing work'},
    {'name': 'Efficiency', 'formula': 'η = (useful output / total input) × 100%', 'desc': 'Energy efficiency'},
  ],
  '💧 Fluids': [
    {'name': 'Pressure', 'formula': 'P = F/A', 'desc': 'Force per unit area'},
    {'name': 'Fluid Pressure', 'formula': 'P = ρgh', 'desc': 'Pressure at depth h'},
    {'name': 'Continuity', 'formula': 'A₁v₁ = A₂v₂', 'desc': 'Conservation of flow rate'},
    {'name': "Bernoulli's", 'formula': 'P + ½ρv² + ρgh = const', 'desc': "Bernoulli's principle"},
    {'name': 'Buoyancy', 'formula': 'F_b = ρVg', 'desc': 'Archimedes principle'},
  ],
  '🔧 Materials': [
    {"name": "Young's Modulus", 'formula': 'E = σ/ε = (F/A)/(ΔL/L)', 'desc': 'Elastic modulus'},
    {'name': 'Stress', 'formula': 'σ = F/A', 'desc': 'Force per unit area'},
    {'name': 'Strain', 'formula': 'ε = ΔL/L', 'desc': 'Fractional change in length'},
    {'name': 'Thermal Expansion', 'formula': 'ΔL = αL₀ΔT', 'desc': 'Change in length due to heat'},
  ],
  '🔥 Thermo': [
    {'name': 'Heat Transfer', 'formula': 'Q = mcΔT', 'desc': 'Heat = mass × specific heat × ΔT'},
    {'name': 'Ideal Gas Law', 'formula': 'PV = nRT', 'desc': 'Pressure × Volume = nRT'},
    {'name': '1st Law of Thermo', 'formula': 'ΔU = Q - W', 'desc': 'Change in internal energy'},
    {'name': 'Efficiency', 'formula': 'η = 1 - T_c/T_h', 'desc': 'Carnot efficiency'},
    {'name': 'Conduction', 'formula': 'Q/t = kA(ΔT/d)', 'desc': 'Rate of heat conduction'},
  ],
};

class FormulasScreen extends StatefulWidget {
  const FormulasScreen({super.key});
  @override
  State<FormulasScreen> createState() => _FormulasScreenState();
}

class _FormulasScreenState extends State<FormulasScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: '📐 Formulas'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search formulas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ..._formulas.keys.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = _selectedCategory == cat ? null : cat),
                        selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _formulas.entries
                  .where((e) => _selectedCategory == null || e.key == _selectedCategory)
                  .map((entry) {
                final filtered = entry.value.where((f) =>
                    _search.isEmpty ||
                    f['name']!.toLowerCase().contains(_search) ||
                    f['formula']!.toLowerCase().contains(_search)).toList();
                if (filtered.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(entry.key,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ...filtered.map((f) => _FormulaCard(formula: f)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final Map<String, String> formula;
  const _FormulaCard({required this.formula});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formula['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(formula['formula']!,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(formula['desc']!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formula['formula']!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formula copied!'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
