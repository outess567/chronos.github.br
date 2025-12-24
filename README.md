import React, { useState, useEffect, useRef, useMemo } from 'react';
import { 
  Play, 
  Pause, 
  Square, 
  CheckCircle2, 
  Target, 
  MoreVertical, 
  Clock, 
  ChevronRight, 
  Plus, 
  Trash2,
  Minimize2,
  Calendar as CalendarIcon,
  X,
  Edit2,
  Save
} from 'lucide-react';

// --- Utilitários ---

const formatTime = (seconds) => {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
};

const formatShortTime = (seconds) => {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  return `${h}h ${m}m`;
};

const getDaysUntilSunday = () => {
  const today = new Date();
  const dayOfWeek = today.getDay();
  return dayOfWeek === 0 ? 0 : 7 - dayOfWeek;
};

const COLORS = [
  'bg-emerald-500', 'bg-blue-500', 'bg-violet-500', 
  'bg-orange-500', 'bg-rose-500', 'bg-amber-500', 'bg-cyan-500'
];

// --- Mock Data ---

const INITIAL_SUBJECTS = [
  { id: 1, name: 'Matemática Avançada', color: 'bg-emerald-500', goalHours: 10, completedSeconds: 14400 },
  { id: 2, name: 'Direito Constitucional', color: 'bg-blue-500', goalHours: 8, completedSeconds: 3600 },
];

const INITIAL_TASKS = [
  { id: 1, text: 'Revisar Logaritmos', completed: true, date: new Date().toLocaleDateString() },
  { id: 2, text: 'Ler Cap. 4 de Constitucional', completed: false, date: new Date().toLocaleDateString() },
];

export default function ChronosApp() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [subjects, setSubjects] = useState(INITIAL_SUBJECTS);
  const [tasks, setTasks] = useState(INITIAL_TASKS);
  
  // Estados de Calendário
  const [currentDate, setCurrentDate] = useState(new Date());
  
  // Estados de Estudo/Imersão
  const [activeSubjectId, setActiveSubjectId] = useState(null);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [isImmersionMode, setIsImmersionMode] = useState(false);
  
  // Estados de Modais
  const [editingSubject, setEditingSubject] = useState(null);
  const [isAddingSubject, setIsAddingSubject] = useState(false);
  const [showSubjectMenu, setShowSubjectMenu] = useState(null);

  const timerRef = useRef(null);
  const activeSubject = subjects.find(s => s.id === activeSubjectId);

  // --- Cálculos Globais ---

  const totalGoalSeconds = subjects.reduce((acc, s) => acc + (s.goalHours * 3600), 0);
  const totalCompletedSeconds = subjects.reduce((acc, s) => acc + s.completedSeconds, 0);
  const globalProgress = totalGoalSeconds > 0 ? Math.round((totalCompletedSeconds / totalGoalSeconds) * 100) : 0;

  const totalTasks = tasks.length;
  const completedTasks = tasks.filter(t => t.completed).length;
  const tasksProgress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

  // --- Lógica do Timer ---

  useEffect(() => {
    if (isTimerRunning && activeSubjectId) {
      timerRef.current = setInterval(() => {
        setSubjects(prev => prev.map(sub => {
          if (sub.id === activeSubjectId) {
            return { ...sub, completedSeconds: sub.completedSeconds + 1 };
          }
          return sub;
        }));
      }, 1000);
    } else {
      if (timerRef.current) clearInterval(timerRef.current);
    }
    return () => clearInterval(timerRef.current);
  }, [isTimerRunning, activeSubjectId]);

  // --- Handlers de Matérias ---

  const handleSaveSubject = (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const name = formData.get('name');
    const hours = parseInt(formData.get('hours'));

    if (editingSubject) {
      setSubjects(subjects.map(s => s.id === editingSubject.id ? { ...s, name, goalHours: hours } : s));
      setEditingSubject(null);
    } else {
      const newSub = {
        id: Date.now(),
        name,
        goalHours: hours,
        completedSeconds: 0,
        color: COLORS[subjects.length % COLORS.length]
      };
      setSubjects([...subjects, newSub]);
      setIsAddingSubject(false);
    }
    setShowSubjectMenu(null);
  };

  const deleteSubject = (id) => {
    setSubjects(subjects.filter(s => s.id !== id));
    setShowSubjectMenu(null);
  };

  const changeMonth = (offset) => {
    const newDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + offset, 1);
    setCurrentDate(newDate);
  };

  const daysInMonth = useMemo(() => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const date = new Date(year, month, 1);
    const days = [];
    for (let i = 0; i < date.getDay(); i++) days.push(null);
    while (date.getMonth() === month) {
      days.push(new Date(date));
      date.setDate(date.getDate() + 1);
    }
    return days;
  }, [currentDate]);

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 font-sans flex flex-col overflow-hidden">
      
      {/* Navbar */}
      {!isImmersionMode && (
        <nav className="h-16 border-b border-white/5 flex items-center justify-between px-6 bg-zinc-950/80 backdrop-blur-md sticky top-0 z-10">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-tr from-emerald-600 to-emerald-400 rounded-lg flex items-center justify-center">
              <Clock className="w-5 h-5 text-zinc-950" />
            </div>
            <span className="font-bold text-xl tracking-tight">CHRONOS</span>
          </div>
          
          <div className="flex items-center gap-6">
            <button onClick={() => setActiveTab('dashboard')} className={`text-sm font-medium transition-colors ${activeTab === 'dashboard' ? 'text-emerald-400' : 'text-zinc-500 hover:text-zinc-300'}`}>Metas</button>
            <button onClick={() => setActiveTab('planning')} className={`text-sm font-medium transition-colors ${activeTab === 'planning' ? 'text-emerald-400' : 'text-zinc-500 hover:text-zinc-300'}`}>Planejamento</button>
            <div className="w-px h-4 bg-white/10 mx-2"></div>
            <div className="flex items-center gap-3 text-right">
              <div className="hidden sm:block">
                <p className="text-xs text-zinc-400">Ciclo Semanal</p>
                <p className="text-xs font-bold text-zinc-200">
                  {getDaysUntilSunday() === 0 ? "Reseta hoje!" : `Encerra em ${getDaysUntilSunday()} dias`}
                </p>
              </div>
            </div>
          </div>
        </nav>
      )}

      <main className="flex-1 overflow-y-auto relative">
        
        {/* VIEW: DASHBOARD */}
        {activeTab === 'dashboard' && !isImmersionMode && (
          <div className="p-6 max-w-7xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div className="space-y-1">
                <h1 className="text-3xl font-light">Painel de <span className="font-bold text-emerald-400">Progresso</span></h1>
                <div className="flex items-center gap-4 text-sm">
                  <span className="text-zinc-400">Concluído: <b className="text-emerald-400">{globalProgress}%</b></span>
                  <span className="text-zinc-400">Meta Semanal: <b className="text-zinc-200">{Math.round(totalGoalSeconds/3600)}h</b></span>
                </div>
              </div>
              <button 
                onClick={() => setIsAddingSubject(true)}
                className="flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-zinc-950 px-4 py-2 rounded-xl font-bold transition-all active:scale-95"
              >
                <Plus className="w-5 h-5" /> Nova Matéria
              </button>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {subjects.map(subject => {
                const totalSeconds = subject.goalHours * 3600;
                const progress = Math.min(100, (subject.completedSeconds / totalSeconds) * 100);
                const remaining = Math.max(0, totalSeconds - subject.completedSeconds);

                return (
                  <div key={subject.id} className="group relative bg-zinc-900/40 border border-white/5 rounded-2xl p-6 hover:border-emerald-500/30 transition-all">
                    <div className="flex justify-between items-start mb-6">
                      <div className="flex items-center gap-3">
                        <div className={`w-3 h-3 rounded-full ${subject.color}`}></div>
                        <h3 className="font-semibold text-lg">{subject.name}</h3>
                      </div>
                      
                      <div className="relative">
                        <button 
                          onClick={() => setShowSubjectMenu(showSubjectMenu === subject.id ? null : subject.id)}
                          className="text-zinc-600 hover:text-zinc-300 p-1"
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>
                        
                        {showSubjectMenu === subject.id && (
                          <div className="absolute right-0 mt-2 w-48 bg-zinc-900 border border-white/10 rounded-xl shadow-2xl z-20 py-2">
                            <button 
                              onClick={() => setEditingSubject(subject)}
                              className="w-full text-left px-4 py-2 text-sm text-zinc-300 hover:bg-zinc-800 flex items-center gap-2"
                            >
                              <Edit2 className="w-4 h-4" /> Editar Meta
                            </button>
                            <button 
                              onClick={() => deleteSubject(subject.id)}
                              className="w-full text-left px-4 py-2 text-sm text-red-400 hover:bg-red-500/10 flex items-center gap-2"
                            >
                              <Trash2 className="w-4 h-4" /> Excluir
                            </button>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="space-y-4">
                      <div className="flex justify-between items-end">
                        <div>
                          <p className="text-xs text-zinc-500 uppercase font-medium">Restante</p>
                          <p className="text-2xl font-mono font-bold text-white mt-1">
                            {remaining === 0 ? "Concluído!" : formatShortTime(remaining)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-xs text-zinc-500">Meta</p>
                          <p className="text-sm font-medium">{subject.goalHours}h</p>
                        </div>
                      </div>

                      <div className="h-2 w-full bg-zinc-800 rounded-full overflow-hidden">
                        <div className={`h-full ${subject.color} transition-all duration-700`} style={{ width: `${progress}%` }}></div>
                      </div>
                      
                      <div className="pt-2 flex justify-between items-center">
                        <span className="text-xs text-zinc-500">{Math.round(progress)}%</span>
                        <button 
                          onClick={() => {
                            setActiveSubjectId(subject.id);
                            setIsImmersionMode(true);
                            setIsTimerRunning(true);
                          }} 
                          className="bg-white text-black px-4 py-2 rounded-lg text-sm font-bold flex items-center gap-2 hover:scale-105 transition-transform"
                        >
                          <Play className="w-4 h-4 fill-current" /> Estudar
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* VIEW: PLANEJAMENTO */}
        {activeTab === 'planning' && !isImmersionMode && (
          <div className="p-6 max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-6">
               <header>
                  <h1 className="text-3xl font-light">Visão <span className="font-bold text-indigo-400">Mensal</span></h1>
                  <p className="text-zinc-500 mt-1 capitalize">{new Date().toLocaleDateString('pt-BR', { day: 'numeric', month: 'long', year: 'numeric' })}</p>
              </header>

              <div className="bg-zinc-900/40 border border-white/5 rounded-2xl p-6">
                <div className="flex justify-between items-center mb-8">
                  <h2 className="text-xl font-bold capitalize">{currentDate.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })}</h2>
                  <div className="flex gap-2">
                    <button onClick={() => changeMonth(-1)} className="p-2 hover:bg-zinc-800 rounded-lg border border-white/5"><ChevronRight className="w-5 h-5 rotate-180" /></button>
                    <button onClick={() => setCurrentDate(new Date())} className="px-3 text-xs font-bold hover:bg-zinc-800 rounded-lg border border-white/5">Hoje</button>
                    <button onClick={() => changeMonth(1)} className="p-2 hover:bg-zinc-800 rounded-lg border border-white/5"><ChevronRight className="w-5 h-5" /></button>
                  </div>
                </div>

                <div className="grid grid-cols-7 gap-2 text-center mb-4">
                  {['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map(d => (
                    <div key={d} className="text-[10px] uppercase font-bold text-zinc-600 tracking-widest">{d}</div>
                  ))}
                </div>
                
                <div className="grid grid-cols-7 gap-2">
                  {daysInMonth.map((date, i) => {
                    if (!date) return <div key={`empty-${i}`} className="aspect-square"></div>;
                    const isToday = date.toDateString() === new Date().toDateString();
                    return (
                      <div key={date.toISOString()} className={`aspect-square rounded-xl flex items-center justify-center relative transition-all border ${isToday ? 'bg-emerald-500/10 border-emerald-500/50 text-emerald-400 font-bold' : 'bg-zinc-900/60 border-transparent hover:bg-zinc-800'}`}>
                        {date.getDate()}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* TAREFAS COM PERCENTUAL */}
            <div className="space-y-6">
               <header>
                <h1 className="text-3xl font-light">Minhas <span className="font-bold text-zinc-400">Tarefas</span></h1>
                <p className="text-sm font-medium mt-1 text-zinc-500">
                  Progresso: <span className={tasksProgress === 100 ? 'text-emerald-400' : 'text-zinc-300'}>{tasksProgress}% concluído</span>
                </p>
              </header>

              <div className="bg-zinc-900/40 border border-white/5 rounded-2xl p-6 min-h-[500px] flex flex-col">
                <div className="flex items-center gap-3 mb-6 bg-zinc-950/50 p-3 rounded-xl border border-white/5">
                  <input 
                    type="text" 
                    placeholder="Nova tarefa para hoje..." 
                    className="bg-transparent w-full outline-none text-sm"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && e.target.value) {
                        setTasks([{ id: Date.now(), text: e.target.value, completed: false, date: new Date().toLocaleDateString() }, ...tasks]);
                        e.target.value = '';
                      }
                    }}
                  />
                </div>

                <div className="space-y-3 flex-1 overflow-y-auto">
                  {tasks.map(task => (
                    <div key={task.id} className="group flex items-center gap-3 p-4 bg-zinc-900/60 border border-white/5 rounded-xl">
                      <button 
                        onClick={() => setTasks(tasks.map(t => t.id === task.id ? {...t, completed: !t.completed} : t))}
                        className={`w-5 h-5 rounded border ${task.completed ? 'bg-emerald-500 border-emerald-500' : 'border-zinc-700'}`}
                      >
                        {task.completed && <CheckCircle2 className="w-3.5 h-3.5 text-zinc-950" />}
                      </button>
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm truncate ${task.completed ? 'text-zinc-600 line-through' : 'text-zinc-200'}`}>{task.text}</p>
                        <p className="text-[10px] text-zinc-500 mt-0.5">{task.date}</p>
                      </div>
                      <button onClick={() => setTasks(tasks.filter(t => t.id !== task.id))} className="opacity-0 group-hover:opacity-100 text-zinc-600 hover:text-red-400"><Trash2 className="w-4 h-4" /></button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* MODO IMERSÃO */}
        {isImmersionMode && activeSubject && (
          <div className="absolute inset-0 z-50 bg-zinc-950 flex flex-col items-center justify-center p-6 animate-in fade-in duration-500">
            <button onClick={() => setIsImmersionMode(false)} className="absolute top-8 right-8 p-3 bg-zinc-900 hover:bg-zinc-800 rounded-full border border-white/5">
              <Minimize2 className="w-6 h-6 text-zinc-400" />
            </button>
            <div className="text-center space-y-8">
              <h2 className="text-5xl font-bold tracking-tight">{activeSubject.name}</h2>
              <div className="text-[10rem] md:text-[14rem] font-mono font-black tabular-nums tracking-tighter text-white">
                {formatTime(activeSubject.completedSeconds)}
              </div>
              <div className="flex items-center justify-center gap-8">
                <button onClick={() => setIsTimerRunning(!isTimerRunning)} className={`w-24 h-24 rounded-full flex items-center justify-center shadow-2xl transition-all ${isTimerRunning ? 'bg-zinc-900 border border-zinc-700 text-zinc-100' : 'bg-emerald-500 text-zinc-950'}`}>
                  {isTimerRunning ? <Pause className="w-10 h-10 fill-current" /> : <Play className="w-10 h-10 fill-current ml-1" />}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* MODAL: ADICIONAR / EDITAR MATÉRIA */}
      {(editingSubject || isAddingSubject) && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-sm z-[100] flex items-center justify-center p-6 animate-in fade-in duration-200">
          <div className="bg-zinc-900 border border-white/10 rounded-3xl p-8 max-w-md w-full space-y-8 shadow-2xl shadow-black">
            <div className="flex justify-between items-center">
              <h2 className="text-2xl font-bold">{editingSubject ? 'Editar Matéria' : 'Nova Matéria'}</h2>
              <button onClick={() => { setEditingSubject(null); setIsAddingSubject(false); }} className="text-zinc-500 hover:text-zinc-100"><X /></button>
            </div>
            
            <form onSubmit={handleSaveSubject} className="space-y-6">
              <div className="space-y-2">
                <label className="text-xs font-bold text-zinc-500 uppercase tracking-widest">Nome da Matéria</label>
                <input 
                  required
                  name="name"
                  defaultValue={editingSubject?.name || ''}
                  placeholder="Ex: Física Quântica"
                  className="w-full bg-zinc-950 border border-white/5 rounded-xl px-4 py-3 outline-none focus:border-emerald-500 transition-colors"
                />
              </div>
              
              <div className="space-y-2">
                <label className="text-xs font-bold text-zinc-500 uppercase tracking-widest">Carga Horária Semanal (Horas)</label>
                <input 
                  required
                  name="hours"
                  type="number"
                  min="1"
                  max="168"
                  defaultValue={editingSubject?.goalHours || 5}
                  className="w-full bg-zinc-950 border border-white/5 rounded-xl px-4 py-3 outline-none focus:border-emerald-500 transition-colors"
                />
              </div>

              <div className="pt-4 flex gap-3">
                 <button 
                  type="button"
                  onClick={() => { setEditingSubject(null); setIsAddingSubject(false); }}
                  className="flex-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 font-bold py-4 rounded-2xl transition-all"
                >
                  Cancelar
                </button>
                <button 
                  type="submit"
                  className="flex-1 bg-emerald-500 hover:bg-emerald-400 text-zinc-950 font-bold py-4 rounded-2xl transition-all flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/20"
                >
                  <Save className="w-5 h-5" /> Salvar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
