<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chronos - Gestão de Estudos</title>
    <!-- Tailwind CSS para o design -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- React e Babel para funcionamento no navegador -->
    <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;900&display=swap');
        body { font-family: 'Inter', sans-serif; background-color: #09090b; color: #f4f4f5; }
        .custom-scroll::-webkit-scrollbar { width: 6px; }
        .custom-scroll::-webkit-scrollbar-track { background: transparent; }
        .custom-scroll::-webkit-scrollbar-thumb { background: #27272a; border-radius: 10px; }
    </style>
</head>
<body>
    <div id="root"></div>

    <script type="text/babel">
        const { useState, useEffect, useRef, useMemo } = React;

        // Ícones via Lucide (Ajuste para rodar no navegador)
        const Icon = ({ name, className = "w-5 h-5", ...props }) => {
            const [iconSvg, setIconSvg] = useState('');
            useEffect(() => {
                if (window.lucide) {
                    const svg = window.lucide.createIcons();
                }
            }, []);
            return <i data-lucide={name} className={className} {...props}></i>;
        };

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

        const COLORS = ['bg-emerald-500', 'bg-blue-500', 'bg-violet-500', 'bg-orange-500', 'bg-rose-500'];

        function App() {
            const [activeTab, setActiveTab] = useState('dashboard');
            const [subjects, setSubjects] = useState([
                { id: 1, name: 'Matemática Avançada', color: 'bg-emerald-500', goalHours: 10, completedSeconds: 14400 },
                { id: 2, name: 'Direito Constitucional', color: 'bg-blue-500', goalHours: 8, completedSeconds: 3600 }
            ]);
            const [tasks, setTasks] = useState([
                { id: 1, text: 'Revisar Logaritmos', completed: true, date: new Date().toLocaleDateString() }
            ]);
            
            const [currentDate, setCurrentDate] = useState(new Date());
            const [activeSubjectId, setActiveSubjectId] = useState(null);
            const [isTimerRunning, setIsTimerRunning] = useState(false);
            const [isImmersionMode, setIsImmersionMode] = useState(false);
            const [editingSubject, setEditingSubject] = useState(null);
            const [isAddingSubject, setIsAddingSubject] = useState(false);
            const [showSubjectMenu, setShowSubjectMenu] = useState(null);

            const timerRef = useRef(null);

            // Cálculos
            const totalGoalSeconds = subjects.reduce((acc, s) => acc + (s.goalHours * 3600), 0);
            const totalCompletedSeconds = subjects.reduce((acc, s) => acc + s.completedSeconds, 0);
            const globalProgress = totalGoalSeconds > 0 ? Math.round((totalCompletedSeconds / totalGoalSeconds) * 100) : 0;
            const tasksProgress = tasks.length > 0 ? Math.round((tasks.filter(t => t.completed).length / tasks.length) * 100) : 0;

            useEffect(() => {
                if (isTimerRunning && activeSubjectId) {
                    timerRef.current = setInterval(() => {
                        setSubjects(prev => prev.map(sub => 
                            sub.id === activeSubjectId ? { ...sub, completedSeconds: sub.completedSeconds + 1 } : sub
                        ));
                    }, 1000);
                } else {
                    clearInterval(timerRef.current);
                }
                return () => clearInterval(timerRef.current);
            }, [isTimerRunning, activeSubjectId]);

            useEffect(() => {
                if (window.lucide) window.lucide.createIcons();
            }, [activeTab, isImmersionMode, subjects, tasks, showSubjectMenu, isAddingSubject]);

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
                <div className="min-h-screen flex flex-col overflow-hidden">
                    {!isImmersionMode && (
                        <nav className="h-16 border-b border-white/5 flex items-center justify-between px-6 bg-zinc-950/80 backdrop-blur-md sticky top-0 z-10">
                            <div className="flex items-center gap-2">
                                <div className="w-8 h-8 bg-emerald-500 rounded-lg flex items-center justify-center">
                                    <Icon name="clock" className="w-5 h-5 text-zinc-950" />
                                </div>
                                <span className="font-bold text-xl tracking-tight">CHRONOS</span>
                            </div>
                            <div className="flex items-center gap-6">
                                <button onClick={() => setActiveTab('dashboard')} className={`text-sm font-medium ${activeTab === 'dashboard' ? 'text-emerald-400' : 'text-zinc-500'}`}>Metas</button>
                                <button onClick={() => setActiveTab('planning')} className={`text-sm font-medium ${activeTab === 'planning' ? 'text-emerald-400' : 'text-zinc-500'}`}>Planeamento</button>
                                <div className="hidden sm:block text-right ml-4 border-l border-white/10 pl-4">
                                    <p className="text-[10px] text-zinc-500 uppercase tracking-tighter">Ciclo Semanal</p>
                                    <p className="text-xs font-bold text-zinc-200">{getDaysUntilSunday() === 0 ? "Reseta hoje" : `Encerra em ${getDaysUntilSunday()} dias`}</p>
                                </div>
                            </div>
                        </nav>
                    )}

                    <main className="flex-1 overflow-y-auto custom-scroll">
                        {activeTab === 'dashboard' && !isImmersionMode && (
                            <div className="p-6 max-w-7xl mx-auto space-y-8">
                                <header className="flex flex-col md:flex-row md:items-end justify-between gap-4">
                                    <div>
                                        <h1 className="text-3xl font-light">Painel de <span className="font-bold text-emerald-400">Progresso</span></h1>
                                        <div className="flex gap-4 mt-2 text-sm text-zinc-500">
                                            <span>Concluído: <b className="text-emerald-400">{globalProgress}%</b></span>
                                            <span>Meta Total: <b className="text-zinc-200">{Math.round(totalGoalSeconds/3600)}h</b></span>
                                        </div>
                                    </div>
                                    <button onClick={() => setIsAddingSubject(true)} className="bg-emerald-500 text-zinc-950 px-5 py-2.5 rounded-xl font-bold flex items-center gap-2 hover:bg-emerald-400 transition-colors">
                                        <Icon name="plus" className="w-5 h-5" /> Nova Matéria
                                    </button>
                                </header>

                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                    {subjects.map(s => {
                                        const total = s.goalHours * 3600;
                                        const prog = Math.min(100, (s.completedSeconds / total) * 100);
                                        return (
                                            <div key={s.id} className="bg-zinc-900/40 border border-white/5 rounded-2xl p-6 group">
                                                <div className="flex justify-between mb-6">
                                                    <div className="flex items-center gap-3">
                                                        <div className={`w-3 h-3 rounded-full ${s.color}`}></div>
                                                        <h3 className="font-semibold">{s.name}</h3>
                                                    </div>
                                                    <button onClick={() => setShowSubjectMenu(showSubjectMenu === s.id ? null : s.id)} className="text-zinc-600 hover:text-zinc-300">
                                                        <Icon name="more-vertical" />
                                                    </button>
                                                    {showSubjectMenu === s.id && (
                                                        <div className="absolute translate-y-8 right-6 w-40 bg-zinc-900 border border-white/10 rounded-xl shadow-2xl z-20 py-1">
                                                            <button onClick={() => setEditingSubject(s)} className="w-full text-left px-4 py-2 text-sm hover:bg-zinc-800 flex items-center gap-2"><Icon name="edit-2" className="w-3.5 h-3.5" /> Editar</button>
                                                            <button onClick={() => setSubjects(subjects.filter(sub => sub.id !== s.id))} className="w-full text-left px-4 py-2 text-sm text-red-400 hover:bg-red-500/10 flex items-center gap-2"><Icon name="trash-2" className="w-3.5 h-3.5" /> Apagar</button>
                                                        </div>
                                                    )}
                                                </div>
                                                <div className="space-y-4">
                                                    <div className="flex justify-between items-end">
                                                        <div>
                                                            <p className="text-[10px] text-zinc-500 uppercase">Restante</p>
                                                            <p className="text-xl font-mono font-bold">{formatShortTime(Math.max(0, total - s.completedSeconds))}</p>
                                                        </div>
                                                        <p className="text-sm text-zinc-500">{s.goalHours}h meta</p>
                                                    </div>
                                                    <div className="h-1.5 w-full bg-zinc-800 rounded-full overflow-hidden">
                                                        <div className={`h-full ${s.color} transition-all duration-500`} style={{width: `${prog}%`}}></div>
                                                    </div>
                                                    <div className="flex justify-between items-center pt-2">
                                                        <span className="text-xs text-zinc-500">{Math.round(prog)}%</span>
                                                        <button onClick={() => { setActiveSubjectId(s.id); setIsImmersionMode(true); setIsTimerRunning(true); }} className="bg-white text-black px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5">
                                                            <Icon name="play" className="w-3 h-3 fill-current" /> Estudar
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>
                        )}

                        {activeTab === 'planning' && !isImmersionMode && (
                            <div className="p-6 max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">
                                <div className="lg:col-span-2 space-y-6">
                                    <header>
                                        <h1 className="text-3xl font-light">Visão <span className="font-bold text-indigo-400">Mensal</span></h1>
                                        <p className="text-zinc-500 capitalize mt-1">{new Date().toLocaleDateString('pt-pt', {day: 'numeric', month: 'long', year: 'numeric'})}</p>
                                    </header>
                                    <div className="bg-zinc-900/40 border border-white/5 rounded-2xl p-6 text-sm">
                                        <div className="flex justify-between items-center mb-6">
                                            <h2 className="font-bold capitalize">{currentDate.toLocaleDateString('pt-pt', {month: 'long', year: 'numeric'})}</h2>
                                            <div className="flex gap-1">
                                                <button onClick={() => setCurrentDate(new Date(currentDate.setMonth(currentDate.getMonth()-1)))} className="p-1.5 hover:bg-zinc-800 rounded-lg"><Icon name="chevron-left" /></button>
                                                <button onClick={() => setCurrentDate(new Date())} className="px-2 text-[10px] font-bold uppercase">Hoje</button>
                                                <button onClick={() => setCurrentDate(new Date(currentDate.setMonth(currentDate.getMonth()+1)))} className="p-1.5 hover:bg-zinc-800 rounded-lg"><Icon name="chevron-right" /></button>
                                            </div>
                                        </div>
                                        <div className="grid grid-cols-7 gap-1 text-center font-bold text-zinc-600 text-[10px] mb-2 uppercase">
                                            {['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map(d => <div key={d}>{d}</div>)}
                                        </div>
                                        <div className="grid grid-cols-7 gap-1">
                                            {daysInMonth.map((d, i) => d ? (
                                                <div key={i} className={`aspect-square flex items-center justify-center rounded-lg border ${d.toDateString() === new Date().toDateString() ? 'bg-emerald-500/10 border-emerald-500/50 text-emerald-400 font-bold' : 'border-transparent hover:bg-zinc-800'}`}>
                                                    {d.getDate()}
                                                </div>
                                            ) : <div key={i}></div>)}
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-6">
                                    <header>
                                        <h1 className="text-3xl font-light">Minhas <span className="font-bold text-zinc-400">Tarefas</span></h1>
                                        <p className="text-xs mt-1 text-zinc-500">Progresso: <span className="text-emerald-400">{tasksProgress}%</span></p>
                                    </header>
                                    <div className="bg-zinc-900/40 border border-white/5 rounded-2xl p-4 flex flex-col h-[500px]">
                                        <input 
                                            placeholder="Nova tarefa..." 
                                            className="bg-zinc-950 border border-white/5 rounded-xl p-3 text-sm outline-none focus:border-emerald-500/50 mb-4"
                                            onKeyDown={(e) => {
                                                if(e.key === 'Enter' && e.target.value) {
                                                    setTasks([{id: Date.now(), text: e.target.value, completed: false, date: new Date().toLocaleDateString()}, ...tasks]);
                                                    e.target.value = '';
                                                }
                                            }}
                                        />
                                        <div className="space-y-2 overflow-y-auto flex-1 custom-scroll pr-1">
                                            {tasks.map(t => (
                                                <div key={t.id} className="group flex items-center gap-3 p-3 bg-zinc-900/60 rounded-xl border border-white/5">
                                                    <button onClick={() => setTasks(tasks.map(tk => tk.id === t.id ? {...tk, completed: !tk.completed} : tk))} className={`w-4 h-4 rounded border ${t.completed ? 'bg-emerald-500 border-emerald-500' : 'border-zinc-700'}`}>
                                                        {t.completed && <Icon name="check" className="w-3 h-3 text-zinc-950" />}
                                                    </button>
                                                    <div className="flex-1 min-w-0">
                                                        <p className={`text-xs truncate ${t.completed ? 'text-zinc-600 line-through' : ''}`}>{t.text}</p>
                                                        <p className="text-[9px] text-zinc-600">{t.date}</p>
                                                    </div>
                                                    <button onClick={() => setTasks(tasks.filter(tk => tk.id !== t.id))} className="opacity-0 group-hover:opacity-100 text-zinc-600 hover:text-red-400"><Icon name="trash-2" className="w-3.5 h-3.5" /></button>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </main>

                    {isImmersionMode && (
                        <div className="fixed inset-0 bg-zinc-950 z-[100] flex flex-col items-center justify-center p-6">
                            <button onClick={() => setIsImmersionMode(false)} className="absolute top-8 right-8 text-zinc-500 hover:text-white"><Icon name="minimize-2" className="w-8 h-8" /></button>
                            <h2 className="text-4xl font-bold mb-4">{subjects.find(s => s.id === activeSubjectId)?.name}</h2>
                            <div className="text-[12rem] font-black font-mono tracking-tighter">{formatTime(subjects.find(s => s.id === activeSubjectId)?.completedSeconds || 0)}</div>
                            <button onClick={() => setIsTimerRunning(!isTimerRunning)} className={`w-24 h-24 rounded-full flex items-center justify-center ${isTimerRunning ? 'bg-zinc-900 border border-zinc-700' : 'bg-emerald-500 text-zinc-950'}`}>
                                <Icon name={isTimerRunning ? 'pause' : 'play'} className="w-10 h-10 fill-current" />
                            </button>
                        </div>
                    )}

                    {(isAddingSubject || editingSubject) && (
                        <div className="fixed inset-0 bg-black/90 backdrop-blur-sm z-[200] flex items-center justify-center p-6">
                            <form onSubmit={(e) => {
                                e.preventDefault();
                                const name = e.target.name.value;
                                const hours = parseInt(e.target.hours.value);
                                if(editingSubject) {
                                    setSubjects(subjects.map(s => s.id === editingSubject.id ? {...s, name, goalHours: hours} : s));
                                    setEditingSubject(null);
                                } else {
                                    setSubjects([...subjects, {id: Date.now(), name, goalHours: hours, completedSeconds: 0, color: COLORS[subjects.length % COLORS.length]}]);
                                    setIsAddingSubject(false);
                                }
                            }} className="bg-zinc-900 border border-white/10 p-8 rounded-3xl w-full max-w-sm space-y-6">
                                <h2 className="text-xl font-bold">{editingSubject ? 'Editar' : 'Nova'} Matéria</h2>
                                <div className="space-y-4">
                                    <input name="name" defaultValue={editingSubject?.name || ''} placeholder="Nome da matéria" className="w-full bg-zinc-950 border border-white/5 p-3 rounded-xl outline-none" required />
                                    <input name="hours" type="number" defaultValue={editingSubject?.goalHours || 5} placeholder="Horas semanais" className="w-full bg-zinc-950 border border-white/5 p-3 rounded-xl outline-none" required />
                                </div>
                                <div className="flex gap-2">
                                    <button type="button" onClick={() => {setIsAddingSubject(false); setEditingSubject(null);}} className="flex-1 py-3 font-bold text-zinc-500">Cancelar</button>
                                    <button type="submit" className="flex-1 py-3 bg-emerald-500 text-zinc-950 rounded-xl font-bold">Gravar</button>
                                </div>
                            </form>
                        </div>
                    )}
                </div>
            );
        }

        const root = ReactDOM.createRoot(document.getElementById('root'));
        root.render(<App />);
    </script>
</body>
</html>
