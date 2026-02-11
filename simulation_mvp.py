import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# === 1. 参数配置 (Configuration) ===
L, W = 20, 6             # 走廊长度和宽度
AGENT_RADIUS = 0.3       # Agent 半径
V_BASE = 0.15            # 每步基础位移 (相当于 1.2m/s / 20fps)
D_MAX = 4.0              # ToF 最大量程
D_SAFE = 2.0             # 触觉触发距离阈值
SIGMA = 0.05             # 传感器噪声标准差
TAU_REACT = 4            # 反应延迟 (步数)

# 障碍物列表 (x, y, radius)
OBSTACLES = [(5, 2, 0.5), (10, 4, 0.6), (15, 2.5, 0.4), (8, 5, 0.5)]

class Simulation:
    def __init__(self):
        self.pos = np.array([1.0, 3.0])  # 起点
        self.theta = 0.0                 # 朝向 (弧度)
        self.collisions = 0
        self.history_x, self.history_y = [], []
        self.action_queue = []           # 延迟队列
        self.finished = False

    def get_tof_distance(self, angle_offset):
        """模拟射线检测"""
        ray_angle = self.theta + angle_offset
        min_d = D_MAX
        
        # 简化计算：射线与圆的碰撞
        for ox, oy, orad in OBSTACLES:
            dx, dy = ox - self.pos[0], oy - self.pos[1]
            dist_to_center = np.sqrt(dx**2 + dy**2)
            # 计算射线方向与物体中心的夹角
            angle_to_center = np.arctan2(dy, dx)
            diff = (ray_angle - angle_to_center + np.pi) % (2 * np.pi) - np.pi
            
            if abs(diff) < 0.2: # 简化：如果角度对得上
                d = dist_to_center - orad
                if d < min_d: min_d = d
        
        # 模拟墙壁 (y=0 和 y=W)
        dist_to_top = (W - self.pos[1]) / (np.sin(ray_angle) + 1e-6)
        dist_to_bot = (0 - self.pos[1]) / (np.sin(ray_angle) + 1e-6)
        for d in [dist_to_top, dist_to_bot]:
            if d > 0: min_d = min(min_d, d)

        # 加噪与截断
        res = min_d + np.random.normal(0, SIGMA)
        return np.clip(res, 0, D_MAX)

    def update(self, frame):
        if self.finished: return
        
        # 1. 感知 (左, 中, 右)
        d_L = self.get_tof_distance(np.deg2rad(30))
        d_F = self.get_tof_distance(0)
        d_R = self.get_tof_distance(np.deg2rad(-30))

        # 2. 映射触觉强度 (MVP 逻辑: 越近震动越强)
        i_L = max(0, (D_SAFE - d_L) / D_SAFE) if d_L < D_SAFE else 0
        i_R = max(0, (D_SAFE - d_R) / D_SAFE) if d_R < D_SAFE else 0

        # 3. 决策策略
        action = "FORWARD"
        if d_F < 0.6: action = "STOP"
        elif i_L > i_R and i_L > 0.1: action = "TURN_RIGHT"
        elif i_R > i_L and i_R > 0.1: action = "TURN_LEFT"

        # 4. 反应延迟处理
        self.action_queue.append(action)
        if len(self.action_queue) > TAU_REACT:
            curr_act = self.action_queue.pop(0)
        else:
            curr_act = "WAIT"

        # 5. 物理更新
        if curr_act == "FORWARD":
            self.pos += [V_BASE * np.cos(self.theta), V_BASE * np.sin(self.theta)]
        elif curr_act == "TURN_LEFT":
            self.theta += 0.15
        elif curr_act == "TURN_RIGHT":
            self.theta -= 0.15

        # 碰撞判定
        for ox, oy, orad in OBSTACLES:
            if np.linalg.norm(self.pos - [ox, oy]) < (AGENT_RADIUS + orad):
                self.collisions += 1
                self.pos -= 0.2 * np.array([np.cos(self.theta), np.sin(self.theta)]) # 弹回

        # 边界限制
        self.pos[1] = np.clip(self.pos[1], AGENT_RADIUS, W - AGENT_RADIUS)
        
        self.history_x.append(self.pos[0])
        self.history_y.append(self.pos[1])

        if self.pos[0] >= L - 1: self.finished = True

# === 2. 可视化绘制 ===
sim = Simulation()
fig, ax = plt.subplots(figsize=(10, 4))

def animate(i):
    sim.update(i)
    ax.clear()
    ax.set_xlim(0, L)
    ax.set_ylim(0, W)
    ax.set_aspect('equal')
    
    # 画走廊边框
    ax.axhline(0, color='black', lw=2)
    ax.axhline(W, color='black', lw=2)
    
    # 画障碍物
    for ox, oy, orad in OBSTACLES:
        circle = plt.Circle((ox, oy), orad, color='gray', alpha=0.5)
        ax.add_patch(circle)
        
    # 画路径和 Agent
    ax.plot(sim.history_x, sim.history_y, 'b--', alpha=0.6)
    agent_circle = plt.Circle(sim.pos, AGENT_RADIUS, color='red' if not sim.finished else 'green')
    ax.add_patch(agent_circle)
    
    # 状态文字反馈
    ax.set_title(f"Step: {i} | Collisions: {sim.collisions} | Pos: {sim.pos[0]:.1f}m")

ani = FuncAnimation(fig, animate, frames=200, interval=50, repeat=False)
plt.show()
