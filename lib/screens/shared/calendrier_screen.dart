import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/calendrier_service.dart';
import '../../models/calendrier_event_model.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart'; 
import '../responsable/responsable_drawer.dart';
import '../technicien/technicien_drawer.dart'; 

class CalendrierScreen extends StatefulWidget {
  final int? technicienId;

  const CalendrierScreen({super.key, this.technicienId});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  final _service = CalendrierService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<CalendrierEventModel> _allEvents = [];
  List<CalendrierEventModel> _filteredEvents = [];
  bool _isLoading = true;
  
  int? _selectedTechnicienId;
  List<Map<String, dynamic>> _techniciens = [{'id': null, 'nom': 'Tous les techniciens'}];
  
  bool _isTechnicienView = false;

  @override
  void initState() {
    super.initState();
    _initializeUserAndLoad();
  }

  Future<void> _initializeUserAndLoad() async {
    if (widget.technicienId != null) {
      _selectedTechnicienId = widget.technicienId;
      _isTechnicienView = true;
    } else {
      final user = await AuthService.getCurrentUser();
      if (user != null && user.type == 'TECHNICIEN') { 
        _selectedTechnicienId = user.id;
        _isTechnicienView = true;
      }
    }

    _loadTechniciens();
    _loadEventsForMonth(_focusedDay);
  }

  Future<void> _loadTechniciens() async {
    if (!_isTechnicienView) {
      try {
        final techs = await _service.getTechniciens();
        if (mounted) {
          setState(() {
            _techniciens = [{'id': null, 'nom': 'Tous les techniciens'}, ...techs];
          });
        }
      } catch (e) {
        debugPrint('Erreur chargement techniciens: $e');
      }
    }
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final debut = DateTime(month.year, month.month, 1);
      final fin = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final events = await _service.getEvenements(
        debut: debut,
        fin: fin,
        technicienId: _selectedTechnicienId, 
      );

      if (mounted) {
        setState(() {
          _allEvents = events;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedTechnicienId == null) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          return event.technicienIds.contains(_selectedTechnicienId);
        }).toList();
      }
    });
  }

  List<CalendrierEventModel> _getEventsForDay(DateTime day) {
    final targetDate = DateTime(day.year, day.month, day.day);
    return _filteredEvents.where((event) {
      final eventDate = DateTime(event.debut.year, event.debut.month, event.debut.day);
      return targetDate == eventDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay = _getEventsForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _isTechnicienView 
          ? const TechnicienDrawer(currentRoute: '/technicien-calendrier')
          : const ResponsableDrawer(currentRoute: '/responsable-calendrier'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _isTechnicienView ? 'Mon Calendrier' : 'Calendrier des interventions',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          if (!_isTechnicienView)
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.orange),
              tooltip: 'Nouvel événement',
              onPressed: _showCreateEventForm,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : Column(
              children: [
                if (!_isTechnicienView) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int?>(
                            value: _selectedTechnicienId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _techniciens.map((tech) {
                              return DropdownMenuItem<int?>(
                                value: tech['id'] as int?,
                                child: Text(tech['nom'] as String, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTechnicienId = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                
                Container(
                  color: Colors.white,
                  child: TableCalendar<CalendrierEventModel>(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.navy),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.navy),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: AppColors.orange.withOpacity(0.3), shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() { 
                          _selectedDay = selectedDay; 
                          _focusedDay = focusedDay; 
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadEventsForMonth(focusedDay);
                    },
                  ),
                ),
                const Divider(height: 1),
                
                Expanded(
                  child: eventsForSelectedDay.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Aucun événement le ${_formatDateFr(_selectedDay!)}', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                              if (!_isTechnicienView) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateEventForm,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Créer un événement'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: eventsForSelectedDay.length,
                          itemBuilder: (context, index) => _buildEventCard(eventsForSelectedDay[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(CalendrierEventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[200]!, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 50, decoration: BoxDecoration(color: event.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(event.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: event.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(event.type.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: event.color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text('${_formatTime(event.debut)} - ${_formatTime(event.fin)}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                      if (event.lieu != null && event.lieu!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(child: Text(event.lieu!, style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateEventForm(
        techniciens: _techniciens.where((t) => t['id'] != null).toList(),
        onCreated: () {
          Navigator.pop(context);
          _loadEventsForMonth(_focusedDay);
        },
      ),
    );
  }

  String _formatDateFr(DateTime date) {
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// WIDGET DU FORMULAIRE (Bottom Sheet) - Réservé au Responsable
// ============================================================================
class _CreateEventForm extends StatefulWidget {
  final List<Map<String, dynamic>> techniciens;
  final VoidCallback onCreated;

  const _CreateEventForm({required this.techniciens, required this.onCreated});

  @override
  State<_CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<_CreateEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = CalendrierService();

  final _titreCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'REUNION';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(hours: 1));
  final List<int> _selectedTechIds = [];
  bool _isSubmitting = false;

  Future<void> _pickDateTime(bool isDebut) async {
    final initial = isDebut ? _dateDebut : _dateFin;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time != null && mounted) {
        setState(() {
          final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isDebut) {
            _dateDebut = newDateTime;
            if (_dateFin.isBefore(_dateDebut)) _dateFin = _dateDebut.add(const Duration(hours: 1));
          } else {
            _dateFin = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateFin.isBefore(_dateDebut)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La date de fin doit être après le début'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.creerEvenement(
        titre: _titreCtrl.text.trim(),
        type: _type,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        lieu: _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
        technicienIds: _selectedTechIds.isEmpty ? null : _selectedTechIds,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement créé avec succès'), backgroundColor: Colors.green));
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nouvel événement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _titreCtrl, decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type d\'événement *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'REUNION', child: Text('Réunion')),
                  DropdownMenuItem(value: 'CONGE', child: Text('Congé')),
                  DropdownMenuItem(value: 'FORMATION', child: Text('Formation')),
                  DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDateTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Début *', border: OutlineInputBorder()),
                        child: Text(_formatDateTime(_dateDebut)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDateTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fin *', border: OutlineInputBorder()),
                        child: Text(_formatDateTime(_dateFin)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _lieuCtrl, decoration: const InputDecoration(labelText: 'Lieu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on, size: 20))),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true)),
              const SizedBox(height: 16),
              if (widget.techniciens.isNotEmpty) ...[
                const Text('Assigner à des techniciens (optionnel)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.techniciens.map((tech) {
                    final isSelected = _selectedTechIds.contains(tech['id']);
                    return FilterChip(
                      label: Text(tech['nom']),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedTechIds.add(tech['id']);
                          else _selectedTechIds.remove(tech['id']);
                        });
                      },
                      selectedColor: AppColors.orange.withOpacity(0.2),
                      checkmarkColor: AppColors.orange,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CRÉER L\'ÉVÉNEMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}